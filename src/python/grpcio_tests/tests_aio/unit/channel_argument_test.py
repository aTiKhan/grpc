# Copyright 2019 The gRPC Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
"""Tests behavior around the Core channel arguments."""

import asyncio
import logging
import unittest
import socket

import grpc
import random

from grpc.experimental import aio
from src.proto.grpc.testing import messages_pb2
from src.proto.grpc.testing import test_pb2_grpc
from tests.unit.framework.common import test_constants
from tests_aio.unit._test_server import start_test_server
from tests_aio.unit._test_base import AioTestBase
# 100 servers in sequence

_RANDOM_SEED = 42

_ENABLE_REUSE_PORT = 'SO_REUSEPORT enabled'
_DISABLE_REUSE_PORT = 'SO_REUSEPORT disabled'
_SOCKET_OPT_SO_REUSEPORT = 'grpc.so_reuseport'
_OPTIONS = (
    (_ENABLE_REUSE_PORT, ((_SOCKET_OPT_SO_REUSEPORT, 1),)),
    (_DISABLE_REUSE_PORT, ((_SOCKET_OPT_SO_REUSEPORT, 0),)),
)

_NUM_SERVER_CREATED = 100

_GRPC_ARG_MAX_RECEIVE_MESSAGE_LENGTH = 'grpc.max_receive_message_length'
_MAX_MESSAGE_LENGTH = 1024

class _TestPointerWrapper(object):

    def __int__(self):
        return 123456


_TEST_CHANNEL_ARGS = (
    ('arg1', b'bytes_val'),
    ('arg2', 'str_val'),
    ('arg3', 1),
    (b'arg4', 'str_val'),
    ('arg6', _TestPointerWrapper()),
)


_INVALID_TEST_CHANNEL_ARGS = [
    {'foo': 'bar'},
    (('key',),),
    'str',
]


async def test_if_reuse_port_enabled(server: aio.Server):
    port = server.add_insecure_port('127.0.0.1:0')
    await server.start()

    try:
        another_socket = socket.socket(family=socket.AF_INET6)
        another_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        another_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEPORT, 1)
        another_socket.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, True)
        another_socket.bind(('127.0.0.1', port))
    except OSError as e:
        assert 'Address already in use' in str(e)
        return False
    else:
        return True
    finally:
        another_socket.close()


class TestChannelArgument(AioTestBase):

    async def setUp(self):
        random.seed(_RANDOM_SEED)

    async def test_server_so_reuse_port_is_set_properly(self):
        for _ in range(_NUM_SERVER_CREATED):
            fact, options = random.choice(_OPTIONS)
            server = aio.server(options=options)
            try:
                result = await test_if_reuse_port_enabled(server)
                if fact == _ENABLE_REUSE_PORT and not result:
                    self.fail('Enabled reuse port in options, but not observed in socket')
                elif fact == _DISABLE_REUSE_PORT and result:
                    self.fail('Disabled reuse port in options, but observed in socket')
            finally:
                await server.stop(None)


    async def test_client(self):
        aio.insecure_channel('[::]:0', options=_TEST_CHANNEL_ARGS)

    async def test_server(self):
        aio.server(options=_TEST_CHANNEL_ARGS)

    async def test_invalid_client_args(self):
        for invalid_arg in _INVALID_TEST_CHANNEL_ARGS:
            self.assertRaises((ValueError, TypeError),
                              aio.insecure_channel,
                              '[::]:0',
                              options=invalid_arg)

    async def test_max_message_length_applied(self):
        address, server = await start_test_server()

        async with aio.insecure_channel(address, options=(
                (_GRPC_ARG_MAX_RECEIVE_MESSAGE_LENGTH, _MAX_MESSAGE_LENGTH),
            )) as channel:
            stub = test_pb2_grpc.TestServiceStub(channel)

            request = messages_pb2.StreamingOutputCallRequest()
            # First request will pass
            request.response_parameters.append(
                messages_pb2.ResponseParameters(size=_MAX_MESSAGE_LENGTH//2,)
            )
            # Second request should fail
            request.response_parameters.append(
                messages_pb2.ResponseParameters(size=_MAX_MESSAGE_LENGTH*2,)
            )

            call = stub.StreamingOutputCall(request)

            response = await call.read()
            self.assertEqual(_MAX_MESSAGE_LENGTH//2, len(response.payload.body))

            with self.assertRaises(aio.AioRpcError) as exception_context:
                await call.read()
            rpc_error = exception_context.exception
            self.assertEqual(grpc.StatusCode.RESOURCE_EXHAUSTED, rpc_error.code())
            self.assertIn(str(_MAX_MESSAGE_LENGTH), rpc_error.details())

            self.assertEqual(grpc.StatusCode.RESOURCE_EXHAUSTED, await call.code())

        await server.stop(None)


if __name__ == '__main__':
    logging.basicConfig(level=logging.DEBUG)
    unittest.main(verbosity=2)
