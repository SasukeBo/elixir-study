defmodule KV.BucketTest do
  use ExUnit.Case, async: true

  setup do
    {:ok, bucket} = KV.Bucket.start_link([])
    %{bucket: bucket, name: "sasuke"}
  end

  test "stores values by key", %{bucket: bucket, name: name} do
    assert KV.Bucket.get(bucket, "milk") == nil
    assert name == "sasuke"

    KV.Bucket.put(bucket, "milk", 3)
    assert KV.Bucket.get(bucket, "milk") == 3
  end
end
