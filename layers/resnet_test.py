# coding=utf-8
# Copyright 2022 The Tensor2Robot Authors.
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

"""Tests for tensor2robot.layers.resnet."""

import functools
from absl.testing import parameterized
from six.moves import range
from tensor2robot.layers import resnet
import tensorflow.compat.v1 as tf


class ResnetTest(tf.test.TestCase, parameterized.TestCase):

  @parameterized.parameters(('',), ('fubar',), ('dummy/scope'))
  def test_intermediate_values(self, scope):
    with tf.variable_scope(scope):
      image = tf.zeros((2, 224, 224, 3), dtype=tf.float32)
      end_points = resnet.resnet_model(image,
                                       is_training=True,
                                       num_classes=1001,
                                       return_intermediate_values=True)
    tensors = ['initial_conv', 'initial_max_pool', 'pre_final_pool',
               'final_reduce_mean', 'final_dense']
    tensors += [
        'block_layer{}'.format(i + 1) for i in range(4)]
    self.assertEqual(set(tensors), set(end_points.keys()))

  @parameterized.parameters(
      (18, [True, True, True, True]),
      (50, [True, False, True, False]))
  def test_film(self, resnet_size, enabled_blocks):
    image = tf.zeros((2, 224, 224, 3), dtype=tf.float32)
    embedding = tf.zeros((2, 100), dtype=tf.float32)
    film_generator_fn = functools.partial(
        resnet.linear_film_generator, enabled_block_layers=enabled_blocks)
    _ = resnet.resnet_model(image,
                            is_training=True,
                            num_classes=1001,
                            resnet_size=resnet_size,
                            return_intermediate_values=True,
                            film_generator_fn=film_generator_fn,
                            film_generator_input=embedding)

  def test_malformed_film_raises(self):
    image = tf.zeros((2, 224, 224, 3), dtype=tf.float32)
    embedding = tf.zeros((2, 100), dtype=tf.float32)
    film_generator_fn = functools.partial(
        resnet.linear_film_generator, enabled_block_layers=[True]*5)
    with self.assertRaises(ValueError):
      _ = resnet.resnet_model(image,
                              is_training=True,
                              num_classes=1001,
                              resnet_size=18,
                              return_intermediate_values=True,
                              film_generator_fn=film_generator_fn,
                              film_generator_input=embedding)

if __name__ == '__main__':
  tf.test.main()
