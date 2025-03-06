# SPDX-FileCopyrightText: 2018 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule InputEvent.ReportTest do
  use ExUnit.Case

  alias InputEvent.Report

  test "decodes mouse move events" do
    assert Report.decode(<<2, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>) == [
             [{:ev_rel, :rel_y, 1}]
           ]

    assert Report.decode(<<2, 0, 0, 0, 249, 255, 255, 255, 0, 0, 0, 0, 0, 0, 0, 0>>) == [
             [{:ev_rel, :rel_x, -7}]
           ]

    assert Report.decode(
             <<2, 0, 0, 0, 8, 0, 0, 0, 2, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
           ) == [[{:ev_rel, :rel_x, 8}, {:ev_rel, :rel_y, 1}]]
  end

  test "decodes mouse button presses" do
    assert Report.decode(
             <<4, 0, 4, 0, 1, 0, 9, 0, 1, 0, 16, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
           ) == [[{:ev_msc, :msc_scan, 589_825}, {:ev_key, :btn_left, 1}]]

    assert Report.decode(
             <<4, 0, 4, 0, 1, 0, 9, 0, 1, 0, 16, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
           ) == [[{:ev_msc, :msc_scan, 589_825}, {:ev_key, :btn_left, 0}]]

    assert Report.decode(
             <<4, 0, 4, 0, 2, 0, 9, 0, 1, 0, 17, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
           ) == [[{:ev_msc, :msc_scan, 589_826}, {:ev_key, :btn_right, 1}]]

    assert Report.decode(
             <<4, 0, 4, 0, 3, 0, 9, 0, 1, 0, 18, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
           ) == [[{:ev_msc, :msc_scan, 589_827}, {:ev_key, :btn_middle, 1}]]
  end

  test "decodes mouse scroll wheel" do
    assert Report.decode(<<2, 0, 8, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>) ==
             [[{:ev_rel, :rel_wheel, 1}]]
  end

  test "decodes key presses" do
    assert Report.decode(
             <<4, 0, 4, 0, 4, 0, 7, 0, 1, 0, 30, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
           ) == [[{:ev_msc, :msc_scan, 458_756}, {:ev_key, :key_a, 1}]]

    assert Report.decode(
             <<4, 0, 4, 0, 4, 0, 7, 0, 1, 0, 30, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
           ) == [[{:ev_msc, :msc_scan, 458_756}, {:ev_key, :key_a, 0}]]
  end
end
