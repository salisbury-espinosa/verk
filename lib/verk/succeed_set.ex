defmodule Verk.SucceedSet do
  @moduledoc """
  This module interacts with jobs in the succeed set
  """
  import Verk.Dsl
  alias Verk.{SortedSet, Job}

  @max_succeed_jobs Confex.get(:verk, :max_succeed_jobs, 100)
  @timeout 60 * 60 * 24 * 7 # a week

  @succeed_key "succeed"

  @doc "Redis succeed set key"
  def key, do: @succeed_key

  @doc """
  Adds a `job` to the succeed set ordering by `timestamp`

  Optionally a redis connection can be specified
  """
  @spec add(%Job{}, integer,  GenServer.server) :: :ok | {:error, Redix.Error.t}
  def add(job, timestamp, redis \\ Verk.Redis) do
    case Redix.pipeline(redis, [["ZADD", @succeed_key, timestamp, Poison.encode!(job)],
                                ["ZREMRANGEBYSCORE", @succeed_key, "-inf", timestamp - @timeout],
                                ["ZREMRANGEBYRANK", @succeed_key, 0, -@max_succeed_jobs]]) do
      {:ok, _} -> :ok
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  Adds a `job` to the succeed set ordering by `timestamp`, raising if there's an error

  Optionally a redis connection can be specified
  """
  @spec add!(%Job{}, integer,  GenServer.server) :: nil
  def add!(job, timestamp, redis \\ Verk.Redis) do
    bangify(add(job, timestamp, redis))
  end

  @doc """
  Counts how many jobs are inside the succeed set
  """
  @spec count(GenServer.Server) :: {:ok, integer} | {:error, Redix.Error.t}
  def count(redis \\ Verk.Redis), do: SortedSet.count(@succeed_key, redis)

  @doc """
  Counts how many jobs are inside the succeed set, raising if there's an error
  """
  @spec count!(GenServer.Server) :: integer
  def count!(redis \\ Verk.Redis), do: SortedSet.count!(@succeed_key, redis)

  @doc """
  Clears the succeed set
  """
  @spec clear(GenServer.server) :: :ok | {:error, RuntimeError.t | Redix.Error.t}
  def clear(redis \\ Verk.Redis), do: SortedSet.clear(@succeed_key, redis)

  @doc """
  Clears the succeed set, raising if there's an error
  """
  @spec clear!(GenServer.server) :: nil
  def clear!(redis \\ Verk.Redis), do: SortedSet.clear!(@succeed_key, redis)

  @doc """
  List jobs from `start` to `stop`
  """
  @spec range(integer, integer, GenServer.server) :: {:ok, [Verk.Job.T]} | {:error, Redix.Error.t}
  def range(start \\ 0, stop \\ -1, redis \\ Verk.Redis) do
    SortedSet.range(@succeed_key, start, stop, redis)
  end

  @doc """
  List jobs from `start` to `stop`, raising if there's an error
  """
  @spec range!(integer, integer, GenServer.server) :: [Verk.Job.T]
  def range!(start \\ 0, stop \\ -1, redis \\ Verk.Redis) do
    SortedSet.range!(@succeed_key, start, stop, redis)
  end

  @doc """
  Delete the job from the succeed set
  """
  @spec delete_job(%Job{} | String.t, GenServer.server) :: :ok | {:error, RuntimeError.t | Redix.Error.t}
  def delete_job(original_json, redis \\ Verk.Redis)
  def delete_job(%Job{original_json: original_json}, redis) do
    delete_job(original_json, redis)
  end
  def delete_job(original_json, redis), do: SortedSet.delete_job(@succeed_key, original_json, redis)

  @doc """
  Delete the job from the succeed set, raising if there's an exception
  """
  @spec delete_job!(%Job{} | String.t, GenServer.server) :: nil
  def delete_job!(original_json, redis \\ Verk.Redis)
  def delete_job!(%Job{original_json: original_json}, redis) do
    delete_job!(original_json, redis)
  end
  def delete_job!(original_json, redis), do: SortedSet.delete_job!(@succeed_key, original_json, redis)
end
