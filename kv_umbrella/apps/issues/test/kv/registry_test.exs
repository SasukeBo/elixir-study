defmodule KV.RegistryTest do
  use ExUnit.Case, async: true

  setup context do
    # start_supervised!是use ExUnit.Case获得的方法，
    # 这个方法启动的进程会在下一段测试开始时被关闭，
    # 这样避免不同测试之间会对临界区发生竞争。
    # registry = start_supervised!(KV.Registry)
    _ = start_supervised!({KV.Registry, name: context.test})
    %{registry: context.test}
  end

  test "spawns buckets", %{registry: registry} do
    assert KV.Registry.lookup(registry, "shopping") == :error

    KV.Registry.create(registry, "shopping")
    assert {:ok, bucket} = KV.Registry.lookup(registry, "shopping")

    KV.Bucket.put(bucket, "milk", 1)
    assert KV.Bucket.get(bucket, "milk") == 1
  end

  test "removes buckets on exit", %{registry: registry} do
    KV.Registry.create(registry, "shopping")
    {:ok, bucket} = KV.Registry.lookup(registry, "shopping")
    Agent.stop(bucket)

    # Do a call to ensure the registry processed the DOWN message
    _ = KV.Registry.create(registry, "bogus")
    assert KV.Registry.lookup(registry, "shopping") == :error
  end

  # test "removes buckets on exit", %{registry: registry} do
  #   KV.Registry.create(registry, "shopping")
  #   {:ok, bucket} = KV.Registry.lookup(registry, "shopping")
  #   Agent.stop(bucket)
  #   assert KV.Registry.lookup(registry, "shopping") == :error
  # end

  test "removes bucket on crash", %{registry: registry} do
    KV.Registry.create(registry, "shopping")
    {:ok, bucket} = KV.Registry.lookup(registry, "shopping")

    # Stop the bucket with non-normal reason
    Agent.stop(bucket, :shutdown)

    # Do a call to ensure the registry processed the DOWN message
    _ = KV.Registry.create(registry, "bogus")
    assert KV.Registry.lookup(registry, "shopping") == :error
  end

  # test "removes bucket on crash", %{registry: registry} do
  #   KV.Registry.create(registry, "shopping")
  #   {:ok, bucket} = KV.Registry.lookup(registry, "shopping")

  #   # Stop the bucket eith non-normal reason
  #   Agent.stop(bucket, :shutdown)
  #   assert KV.Registry.lookup(registry, "shopping") == :error
  # end
end
