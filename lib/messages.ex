defmodule Extreme.Msg do
  defmodule OperationResult do
    @moduledoc false
    use Protobuf, enum: true, syntax: :proto2

    @type t ::
            integer
            | :Success
            | :PrepareTimeout
            | :CommitTimeout
            | :ForwardTimeout
            | :WrongExpectedVersion
            | :StreamDeleted
            | :InvalidTransaction
            | :AccessDenied

    field(:Success, 0)
    field(:PrepareTimeout, 1)
    field(:CommitTimeout, 2)
    field(:ForwardTimeout, 3)
    field(:WrongExpectedVersion, 4)
    field(:StreamDeleted, 5)
    field(:InvalidTransaction, 6)
    field(:AccessDenied, 7)
  end

  defmodule ReadEventResult do
    @moduledoc false
    use Protobuf, enum: true, syntax: :proto2

    @type t ::
            integer | :Success | :NotFound | :NoStream | :StreamDeleted | :Error | :AccessDenied

    field(:Success, 0)
    field(:NotFound, 1)
    field(:NoStream, 2)
    field(:StreamDeleted, 3)
    field(:Error, 4)
    field(:AccessDenied, 5)
  end

  defmodule ReadStreamResult do
    @moduledoc false
    use Protobuf, enum: true, syntax: :proto2

    @type t ::
            integer
            | :Success
            | :NoStream
            | :StreamDeleted
            | :NotModified
            | :Error
            | :AccessDenied

    field(:Success, 0)
    field(:NoStream, 1)
    field(:StreamDeleted, 2)
    field(:NotModified, 3)
    field(:Error, 4)
    field(:AccessDenied, 5)
  end

  defmodule ReadAllResult do
    @moduledoc false
    use Protobuf, enum: true, syntax: :proto2

    @type t :: integer | :Success | :NotModified | :Error | :AccessDenied

    field(:Success, 0)
    field(:NotModified, 1)
    field(:Error, 2)
    field(:AccessDenied, 3)
  end

  defmodule UpdatePersistentSubscriptionResult do
    @moduledoc false
    use Protobuf, enum: true, syntax: :proto2

    @type t :: integer | :Success | :DoesNotExist | :Fail | :AccessDenied

    field(:Success, 0)
    field(:DoesNotExist, 1)
    field(:Fail, 2)
    field(:AccessDenied, 3)
  end

  defmodule CreatePersistentSubscriptionResult do
    @moduledoc false
    use Protobuf, enum: true, syntax: :proto2

    @type t :: integer | :Success | :AlreadyExists | :Fail | :AccessDenied

    field(:Success, 0)
    field(:AlreadyExists, 1)
    field(:Fail, 2)
    field(:AccessDenied, 3)
  end

  defmodule DeletePersistentSubscriptionResult do
    @moduledoc false
    use Protobuf, enum: true, syntax: :proto2

    @type t :: integer | :Success | :DoesNotExist | :Fail | :AccessDenied

    field(:Success, 0)
    field(:DoesNotExist, 1)
    field(:Fail, 2)
    field(:AccessDenied, 3)
  end

  defmodule NakAction do
    @moduledoc false
    use Protobuf, enum: true, syntax: :proto2

    @type t :: integer | :Unknown | :Park | :Retry | :Skip | :Stop

    field(:Unknown, 0)
    field(:Park, 1)
    field(:Retry, 2)
    field(:Skip, 3)
    field(:Stop, 4)
  end

  defmodule SubscriptionDropReason do
    @moduledoc false
    use Protobuf, enum: true, syntax: :proto2

    @type t ::
            integer
            | :Unsubscribed
            | :AccessDenied
            | :NotFound
            | :PersistentSubscriptionDeleted
            | :SubscriberMaxCountReached

    field(:Unsubscribed, 0)
    field(:AccessDenied, 1)
    field(:NotFound, 2)
    field(:PersistentSubscriptionDeleted, 3)
    field(:SubscriberMaxCountReached, 4)
  end

  defmodule NotHandledReason do
    @moduledoc false
    use Protobuf, enum: true, syntax: :proto2

    @type t :: integer | :NotReady | :TooBusy | :NotMaster

    field(:NotReady, 0)
    field(:TooBusy, 1)
    field(:NotMaster, 2)
  end

  defmodule ScavengeResult do
    @moduledoc false
    use Protobuf, enum: true, syntax: :proto2

    @type t :: integer | :Success | :InProgress | :Failed

    field(:Success, 0)
    field(:InProgress, 1)
    field(:Failed, 2)
  end

  defmodule NewEvent do
    @moduledoc false
    use Protobuf, syntax: :proto2

    @type t :: %__MODULE__{
            event_id: binary,
            event_type: String.t(),
            data_content_type: integer,
            metadata_content_type: integer,
            data: binary,
            metadata: binary
          }

    defstruct event_id: "",
              event_type: "",
              data_content_type: 0,
              metadata_content_type: 0,
              data: "",
              metadata: nil

    field(:event_id, 1, required: true, type: :bytes)
    field(:event_type, 2, required: true, type: :string)
    field(:data_content_type, 3, required: true, type: :int32)
    field(:metadata_content_type, 4, required: true, type: :int32)
    field(:data, 5, required: true, type: :bytes)
    field(:metadata, 6, optional: true, type: :bytes)
  end

  defmodule EventRecord do
    @moduledoc false
    use Protobuf, syntax: :proto2

    @type t :: %__MODULE__{
            event_stream_id: String.t(),
            event_number: integer,
            event_id: binary,
            event_type: String.t(),
            data_content_type: integer,
            metadata_content_type: integer,
            data: binary,
            metadata: binary,
            created: integer,
            created_epoch: integer
          }

    defstruct event_stream_id: "",
              event_number: 0,
              event_id: "",
              event_type: "",
              data_content_type: 0,
              metadata_content_type: 0,
              data: "",
              metadata: nil,
              created: nil,
              created_epoch: nil

    field(:event_stream_id, 1, required: true, type: :string)
    field(:event_number, 2, required: true, type: :int64)
    field(:event_id, 3, required: true, type: :bytes)
    field(:event_type, 4, required: true, type: :string)
    field(:data_content_type, 5, required: true, type: :int32)
    field(:metadata_content_type, 6, required: true, type: :int32)
    field(:data, 7, required: true, type: :bytes)
    field(:metadata, 8, optional: true, type: :bytes)
    field(:created, 9, optional: true, type: :int64)
    field(:created_epoch, 10, optional: true, type: :int64)
  end

  defmodule ResolvedIndexedEvent do
    @moduledoc false
    use Protobuf, syntax: :proto2

    @type t :: %__MODULE__{
            event: EventRecord.t() | nil,
            link: EventRecord.t() | nil
          }

    defstruct event: nil,
              link: nil

    field(:event, 1, required: true, type: EventRecord)
    field(:link, 2, optional: true, type: EventRecord)
  end

  defmodule ResolvedEvent do
    @moduledoc false
    use Protobuf, syntax: :proto2

    @type t :: %__MODULE__{
            event: EventRecord.t() | nil,
            link: EventRecord.t() | nil,
            commit_position: integer,
            prepare_position: integer
          }

    defstruct event: nil,
              link: nil,
              commit_position: 0,
              prepare_position: 0

    field(:event, 1, required: true, type: EventRecord)
    field(:link, 2, optional: true, type: EventRecord)
    field(:commit_position, 3, required: true, type: :int64)
    field(:prepare_position, 4, required: true, type: :int64)
  end

  defmodule WriteEvents do
    @moduledoc false
    use Protobuf, syntax: :proto2

    @type t :: %__MODULE__{
            event_stream_id: String.t(),
            expected_version: integer,
            events: [NewEvent.t()],
            require_master: boolean
          }

    defstruct event_stream_id: "",
              expected_version: 0,
              events: [],
              require_master: false

    field(:event_stream_id, 1, required: true, type: :string)
    field(:expected_version, 2, required: true, type: :int64)
    field(:events, 3, repeated: true, type: NewEvent)
    field(:require_master, 4, required: true, type: :bool)
  end

  defmodule WriteEventsCompleted do
    @moduledoc false
    use Protobuf, syntax: :proto2

    @type t :: %__MODULE__{
            result: OperationResult.t(),
            message: String.t(),
            first_event_number: integer,
            last_event_number: integer,
            prepare_position: integer,
            commit_position: integer,
            current_version: integer
          }

    defstruct result: :Success,
              message: nil,
              first_event_number: 0,
              last_event_number: 0,
              prepare_position: nil,
              commit_position: nil,
              current_version: nil

    field(:result, 1, required: true, type: OperationResult, enum: true)

    field(:message, 2, optional: true, type: :string)
    field(:first_event_number, 3, required: true, type: :int64)
    field(:last_event_number, 4, required: true, type: :int64)
    field(:prepare_position, 5, optional: true, type: :int64)
    field(:commit_position, 6, optional: true, type: :int64)
    field(:current_version, 7, optional: true, type: :int64)
  end

  defmodule DeleteStream do
    @moduledoc false
    use Protobuf, syntax: :proto2

    @type t :: %__MODULE__{
            event_stream_id: String.t(),
            expected_version: integer,
            require_master: boolean,
            hard_delete: boolean
          }

    defstruct event_stream_id: "",
              expected_version: 0,
              require_master: false,
              hard_delete: nil

    field(:event_stream_id, 1, required: true, type: :string)
    field(:expected_version, 2, required: true, type: :int64)
    field(:require_master, 3, required: true, type: :bool)
    field(:hard_delete, 4, optional: true, type: :bool)
  end

  defmodule DeleteStreamCompleted do
    @moduledoc false
    use Protobuf, syntax: :proto2

    @type t :: %__MODULE__{
            result: OperationResult.t(),
            message: String.t(),
            prepare_position: integer,
            commit_position: integer
          }

    defstruct result: :Success,
              message: nil,
              prepare_position: nil,
              commit_position: nil

    field(:result, 1, required: true, type: OperationResult, enum: true)

    field(:message, 2, optional: true, type: :string)
    field(:prepare_position, 3, optional: true, type: :int64)
    field(:commit_position, 4, optional: true, type: :int64)
  end

  defmodule TransactionStart do
    @moduledoc false
    use Protobuf, syntax: :proto2

    @type t :: %__MODULE__{
            event_stream_id: String.t(),
            expected_version: integer,
            require_master: boolean
          }

    defstruct event_stream_id: "",
              expected_version: 0,
              require_master: false

    field(:event_stream_id, 1, required: true, type: :string)
    field(:expected_version, 2, required: true, type: :int64)
    field(:require_master, 3, required: true, type: :bool)
  end

  defmodule TransactionStartCompleted do
    @moduledoc false
    use Protobuf, syntax: :proto2

    @type t :: %__MODULE__{
            transaction_id: integer,
            result: OperationResult.t(),
            message: String.t()
          }

    defstruct transaction_id: 0,
              result: :Success,
              message: nil

    field(:transaction_id, 1, required: true, type: :int64)

    field(:result, 2, required: true, type: OperationResult, enum: true)

    field(:message, 3, optional: true, type: :string)
  end

  defmodule TransactionWrite do
    @moduledoc false
    use Protobuf, syntax: :proto2

    @type t :: %__MODULE__{
            transaction_id: integer,
            events: [NewEvent.t()],
            require_master: boolean
          }

    defstruct transaction_id: 0,
              events: [],
              require_master: false

    field(:transaction_id, 1, required: true, type: :int64)
    field(:events, 2, repeated: true, type: NewEvent)
    field(:require_master, 3, required: true, type: :bool)
  end

  defmodule TransactionWriteCompleted do
    @moduledoc false
    use Protobuf, syntax: :proto2

    @type t :: %__MODULE__{
            transaction_id: integer,
            result: OperationResult.t(),
            message: String.t()
          }

    defstruct transaction_id: 0,
              result: :Success,
              message: nil

    field(:transaction_id, 1, required: true, type: :int64)

    field(:result, 2, required: true, type: OperationResult, enum: true)

    field(:message, 3, optional: true, type: :string)
  end

  defmodule TransactionCommit do
    @moduledoc false
    use Protobuf, syntax: :proto2

    @type t :: %__MODULE__{
            transaction_id: integer,
            require_master: boolean
          }

    defstruct transaction_id: 0,
              require_master: false

    field(:transaction_id, 1, required: true, type: :int64)
    field(:require_master, 2, required: true, type: :bool)
  end

  defmodule TransactionCommitCompleted do
    @moduledoc false
    use Protobuf, syntax: :proto2

    @type t :: %__MODULE__{
            transaction_id: integer,
            result: OperationResult.t(),
            message: String.t(),
            first_event_number: integer,
            last_event_number: integer,
            prepare_position: integer,
            commit_position: integer
          }

    defstruct transaction_id: 0,
              result: :Success,
              message: nil,
              first_event_number: 0,
              last_event_number: 0,
              prepare_position: nil,
              commit_position: nil

    field(:transaction_id, 1, required: true, type: :int64)

    field(:result, 2, required: true, type: OperationResult, enum: true)

    field(:message, 3, optional: true, type: :string)
    field(:first_event_number, 4, required: true, type: :int64)
    field(:last_event_number, 5, required: true, type: :int64)
    field(:prepare_position, 6, optional: true, type: :int64)
    field(:commit_position, 7, optional: true, type: :int64)
  end

  defmodule ReadEvent do
    @moduledoc false
    use Protobuf, syntax: :proto2

    @type t :: %__MODULE__{
            event_stream_id: String.t(),
            event_number: integer,
            resolve_link_tos: boolean,
            require_master: boolean
          }

    defstruct event_stream_id: "",
              event_number: 0,
              resolve_link_tos: false,
              require_master: false

    field(:event_stream_id, 1, required: true, type: :string)
    field(:event_number, 2, required: true, type: :int64)
    field(:resolve_link_tos, 3, required: true, type: :bool)
    field(:require_master, 4, required: true, type: :bool)
  end

  defmodule ReadEventCompleted do
    @moduledoc false
    use Protobuf, syntax: :proto2

    @type t :: %__MODULE__{
            result: ReadEventResult.t(),
            event: ResolvedIndexedEvent.t() | nil,
            error: String.t()
          }

    defstruct result: :Success,
              event: nil,
              error: nil

    field(:result, 1,
      required: true,
      type: ReadEventResult,
      enum: true
    )

    field(:event, 2, required: true, type: ResolvedIndexedEvent)
    field(:error, 3, optional: true, type: :string)
  end

  defmodule ReadStreamEvents do
    @moduledoc false
    use Protobuf, syntax: :proto2

    @type t :: %__MODULE__{
            event_stream_id: String.t(),
            from_event_number: integer,
            max_count: integer,
            resolve_link_tos: boolean,
            require_master: boolean
          }

    defstruct event_stream_id: "",
              from_event_number: 0,
              max_count: 0,
              resolve_link_tos: false,
              require_master: false

    field(:event_stream_id, 1, required: true, type: :string)
    field(:from_event_number, 2, required: true, type: :int64)
    field(:max_count, 3, required: true, type: :int32)
    field(:resolve_link_tos, 4, required: true, type: :bool)
    field(:require_master, 5, required: true, type: :bool)
  end

  defmodule ReadStreamEventsBackward do
    @moduledoc false
    use Protobuf, syntax: :proto2

    @type t :: %__MODULE__{
            event_stream_id: String.t(),
            from_event_number: integer,
            max_count: integer,
            resolve_link_tos: boolean,
            require_master: boolean
          }

    defstruct event_stream_id: "",
              from_event_number: 0,
              max_count: 0,
              resolve_link_tos: false,
              require_master: false

    field(:event_stream_id, 1, required: true, type: :string)
    field(:from_event_number, 2, required: true, type: :int64)
    field(:max_count, 3, required: true, type: :int32)
    field(:resolve_link_tos, 4, required: true, type: :bool)
    field(:require_master, 5, required: true, type: :bool)
  end

  defmodule ReadStreamEventsCompleted do
    @moduledoc false
    use Protobuf, syntax: :proto2

    @type t :: %__MODULE__{
            events: [ResolvedIndexedEvent.t()],
            result: ReadStreamResult.t(),
            next_event_number: integer,
            last_event_number: integer,
            is_end_of_stream: boolean,
            last_commit_position: integer,
            error: String.t()
          }

    defstruct events: [],
              result: :Success,
              next_event_number: 0,
              last_event_number: 0,
              is_end_of_stream: false,
              last_commit_position: 0,
              error: nil

    field(:events, 1, repeated: true, type: ResolvedIndexedEvent)

    field(:result, 2,
      required: true,
      type: ReadStreamResult,
      enum: true
    )

    field(:next_event_number, 3, required: true, type: :int64)
    field(:last_event_number, 4, required: true, type: :int64)
    field(:is_end_of_stream, 5, required: true, type: :bool)
    field(:last_commit_position, 6, required: true, type: :int64)
    field(:error, 7, optional: true, type: :string)
  end

  defmodule ReadAllEvents do
    @moduledoc false
    use Protobuf, syntax: :proto2

    @type t :: %__MODULE__{
            commit_position: integer,
            prepare_position: integer,
            max_count: integer,
            resolve_link_tos: boolean,
            require_master: boolean
          }

    defstruct commit_position: 0,
              prepare_position: 0,
              max_count: 0,
              resolve_link_tos: false,
              require_master: false

    field(:commit_position, 1, required: true, type: :int64)
    field(:prepare_position, 2, required: true, type: :int64)
    field(:max_count, 3, required: true, type: :int32)
    field(:resolve_link_tos, 4, required: true, type: :bool)
    field(:require_master, 5, required: true, type: :bool)
  end

  defmodule ReadAllEventsCompleted do
    @moduledoc false
    use Protobuf, syntax: :proto2

    @type t :: %__MODULE__{
            commit_position: integer,
            prepare_position: integer,
            events: [ResolvedEvent.t()],
            next_commit_position: integer,
            next_prepare_position: integer,
            result: ReadAllEventsCompleted.ReadAllResult.t(),
            error: String.t()
          }

    defstruct commit_position: 0,
              prepare_position: 0,
              events: [],
              next_commit_position: 0,
              next_prepare_position: 0,
              result: nil,
              error: nil

    field(:commit_position, 1, required: true, type: :int64)
    field(:prepare_position, 2, required: true, type: :int64)
    field(:events, 3, repeated: true, type: ResolvedEvent)
    field(:next_commit_position, 4, required: true, type: :int64)
    field(:next_prepare_position, 5, required: true, type: :int64)

    field(:result, 6,
      optional: true,
      type: ReadAllEventsCompleted.ReadAllResult,
      default: :Success,
      enum: true
    )

    field(:error, 7, optional: true, type: :string)
  end

  defmodule CreatePersistentSubscription do
    @moduledoc false
    use Protobuf, syntax: :proto2

    @type t :: %__MODULE__{
            subscription_group_name: String.t(),
            event_stream_id: String.t(),
            resolve_link_tos: boolean,
            start_from: integer,
            message_timeout_milliseconds: integer,
            record_statistics: boolean,
            live_buffer_size: integer,
            read_batch_size: integer,
            buffer_size: integer,
            max_retry_count: integer,
            prefer_round_robin: boolean,
            checkpoint_after_time: integer,
            checkpoint_max_count: integer,
            checkpoint_min_count: integer,
            subscriber_max_count: integer,
            named_consumer_strategy: String.t()
          }

    defstruct subscription_group_name: "",
              event_stream_id: "",
              resolve_link_tos: false,
              start_from: 0,
              message_timeout_milliseconds: 0,
              record_statistics: false,
              live_buffer_size: 0,
              read_batch_size: 0,
              buffer_size: 0,
              max_retry_count: 0,
              prefer_round_robin: false,
              checkpoint_after_time: 0,
              checkpoint_max_count: 0,
              checkpoint_min_count: 0,
              subscriber_max_count: 0,
              named_consumer_strategy: nil

    field(:subscription_group_name, 1, required: true, type: :string)
    field(:event_stream_id, 2, required: true, type: :string)
    field(:resolve_link_tos, 3, required: true, type: :bool)
    field(:start_from, 4, required: true, type: :int64)
    field(:message_timeout_milliseconds, 5, required: true, type: :int32)
    field(:record_statistics, 6, required: true, type: :bool)
    field(:live_buffer_size, 7, required: true, type: :int32)
    field(:read_batch_size, 8, required: true, type: :int32)
    field(:buffer_size, 9, required: true, type: :int32)
    field(:max_retry_count, 10, required: true, type: :int32)
    field(:prefer_round_robin, 11, required: true, type: :bool)
    field(:checkpoint_after_time, 12, required: true, type: :int32)
    field(:checkpoint_max_count, 13, required: true, type: :int32)
    field(:checkpoint_min_count, 14, required: true, type: :int32)
    field(:subscriber_max_count, 15, required: true, type: :int32)
    field(:named_consumer_strategy, 16, optional: true, type: :string)
  end

  defmodule DeletePersistentSubscription do
    @moduledoc false
    use Protobuf, syntax: :proto2

    @type t :: %__MODULE__{
            subscription_group_name: String.t(),
            event_stream_id: String.t()
          }

    defstruct subscription_group_name: "",
              event_stream_id: ""

    field(:subscription_group_name, 1, required: true, type: :string)
    field(:event_stream_id, 2, required: true, type: :string)
  end

  defmodule UpdatePersistentSubscription do
    @moduledoc false
    use Protobuf, syntax: :proto2

    @type t :: %__MODULE__{
            subscription_group_name: String.t(),
            event_stream_id: String.t(),
            resolve_link_tos: boolean,
            start_from: integer,
            message_timeout_milliseconds: integer,
            record_statistics: boolean,
            live_buffer_size: integer,
            read_batch_size: integer,
            buffer_size: integer,
            max_retry_count: integer,
            prefer_round_robin: boolean,
            checkpoint_after_time: integer,
            checkpoint_max_count: integer,
            checkpoint_min_count: integer,
            subscriber_max_count: integer,
            named_consumer_strategy: String.t()
          }

    defstruct subscription_group_name: "",
              event_stream_id: "",
              resolve_link_tos: false,
              start_from: 0,
              message_timeout_milliseconds: 0,
              record_statistics: false,
              live_buffer_size: 0,
              read_batch_size: 0,
              buffer_size: 0,
              max_retry_count: 0,
              prefer_round_robin: false,
              checkpoint_after_time: 0,
              checkpoint_max_count: 0,
              checkpoint_min_count: 0,
              subscriber_max_count: 0,
              named_consumer_strategy: nil

    field(:subscription_group_name, 1, required: true, type: :string)
    field(:event_stream_id, 2, required: true, type: :string)
    field(:resolve_link_tos, 3, required: true, type: :bool)
    field(:start_from, 4, required: true, type: :int64)
    field(:message_timeout_milliseconds, 5, required: true, type: :int32)
    field(:record_statistics, 6, required: true, type: :bool)
    field(:live_buffer_size, 7, required: true, type: :int32)
    field(:read_batch_size, 8, required: true, type: :int32)
    field(:buffer_size, 9, required: true, type: :int32)
    field(:max_retry_count, 10, required: true, type: :int32)
    field(:prefer_round_robin, 11, required: true, type: :bool)
    field(:checkpoint_after_time, 12, required: true, type: :int32)
    field(:checkpoint_max_count, 13, required: true, type: :int32)
    field(:checkpoint_min_count, 14, required: true, type: :int32)
    field(:subscriber_max_count, 15, required: true, type: :int32)
    field(:named_consumer_strategy, 16, optional: true, type: :string)
  end

  defmodule UpdatePersistentSubscriptionCompleted do
    @moduledoc false
    use Protobuf, syntax: :proto2

    @type t :: %__MODULE__{
            result: UpdatePersistentSubscriptionCompleted.UpdatePersistentSubscriptionResult.t(),
            reason: String.t()
          }

    defstruct result: :Success,
              reason: nil

    field(:result, 1,
      required: true,
      type: UpdatePersistentSubscriptionCompleted.UpdatePersistentSubscriptionResult,
      default: :Success,
      enum: true
    )

    field(:reason, 2, optional: true, type: :string)
  end

  defmodule CreatePersistentSubscriptionCompleted do
    @moduledoc false
    use Protobuf, syntax: :proto2

    @type t :: %__MODULE__{
            result: CreatePersistentSubscriptionResult.t(),
            reason: String.t()
          }

    defstruct result: :Success,
              reason: nil

    field(:result, 1,
      required: true,
      type: CreatePersistentSubscriptionResult,
      default: :Success,
      enum: true
    )

    field(:reason, 2, optional: true, type: :string)
  end

  defmodule DeletePersistentSubscriptionCompleted do
    @moduledoc false
    use Protobuf, syntax: :proto2

    @type t :: %__MODULE__{
            result: DeletePersistentSubscriptionResult.t(),
            reason: String.t()
          }

    defstruct result: :Success,
              reason: nil

    field(:result, 1,
      required: true,
      type: DeletePersistentSubscriptionResult,
      default: :Success,
      enum: true
    )

    field(:reason, 2, optional: true, type: :string)
  end

  defmodule ConnectToPersistentSubscription do
    @moduledoc false
    use Protobuf, syntax: :proto2

    @type t :: %__MODULE__{
            subscription_id: String.t(),
            event_stream_id: String.t(),
            allowed_in_flight_messages: integer
          }

    defstruct subscription_id: "",
              event_stream_id: "",
              allowed_in_flight_messages: 0

    field(:subscription_id, 1, required: true, type: :string)
    field(:event_stream_id, 2, required: true, type: :string)
    field(:allowed_in_flight_messages, 3, required: true, type: :int32)
  end

  defmodule PersistentSubscriptionAckEvents do
    @moduledoc false
    use Protobuf, syntax: :proto2

    @type t :: %__MODULE__{
            subscription_id: String.t(),
            processed_event_ids: [binary]
          }

    defstruct subscription_id: "",
              processed_event_ids: []

    field(:subscription_id, 1, required: true, type: :string)
    field(:processed_event_ids, 2, repeated: true, type: :bytes)
  end

  defmodule PersistentSubscriptionNakEvents do
    @moduledoc false
    use Protobuf, syntax: :proto2

    @type t :: %__MODULE__{
            subscription_id: String.t(),
            processed_event_ids: [binary],
            message: String.t(),
            action: NakAction.t()
          }

    defstruct subscription_id: "",
              processed_event_ids: [],
              message: nil,
              action: :Unknown

    field(:subscription_id, 1, required: true, type: :string)
    field(:processed_event_ids, 2, repeated: true, type: :bytes)
    field(:message, 3, optional: true, type: :string)

    field(:action, 4,
      required: true,
      type: NakAction,
      default: :Unknown,
      enum: true
    )
  end

  defmodule PersistentSubscriptionConfirmation do
    @moduledoc false
    use Protobuf, syntax: :proto2

    @type t :: %__MODULE__{
            last_commit_position: integer,
            subscription_id: String.t(),
            last_event_number: integer
          }

    defstruct last_commit_position: 0,
              subscription_id: "",
              last_event_number: nil

    field(:last_commit_position, 1, required: true, type: :int64)
    field(:subscription_id, 2, required: true, type: :string)
    field(:last_event_number, 3, optional: true, type: :int64)
  end

  defmodule PersistentSubscriptionStreamEventAppeared do
    @moduledoc false
    use Protobuf, syntax: :proto2

    @type t :: %__MODULE__{
            event: ResolvedIndexedEvent.t() | nil
          }

    defstruct event: nil

    field(:event, 1, required: true, type: ResolvedIndexedEvent)
  end

  defmodule SubscribeToStream do
    @moduledoc false
    use Protobuf, syntax: :proto2

    @type t :: %__MODULE__{
            event_stream_id: String.t(),
            resolve_link_tos: boolean
          }

    defstruct event_stream_id: "",
              resolve_link_tos: false

    field(:event_stream_id, 1, required: true, type: :string)
    field(:resolve_link_tos, 2, required: true, type: :bool)
  end

  defmodule SubscriptionConfirmation do
    @moduledoc false
    use Protobuf, syntax: :proto2

    @type t :: %__MODULE__{
            last_commit_position: integer,
            last_event_number: integer
          }

    defstruct last_commit_position: 0,
              last_event_number: nil

    field(:last_commit_position, 1, required: true, type: :int64)
    field(:last_event_number, 2, optional: true, type: :int64)
  end

  defmodule StreamEventAppeared do
    @moduledoc false
    use Protobuf, syntax: :proto2

    @type t :: %__MODULE__{
            event: ResolvedEvent.t() | nil
          }

    defstruct event: nil

    field(:event, 1, required: true, type: ResolvedEvent)
  end

  defmodule UnsubscribeFromStream do
    @moduledoc false
    use Protobuf, syntax: :proto2

    @type t :: %__MODULE__{}

    defstruct []
  end

  defmodule SubscriptionDropped do
    @moduledoc false
    use Protobuf, syntax: :proto2

    @type t :: %__MODULE__{
            reason: SubscriptionDropped.SubscriptionDropReason.t()
          }

    defstruct reason: nil

    field(:reason, 1,
      optional: true,
      type: SubscriptionDropped.SubscriptionDropReason,
      default: :Unsubscribed,
      enum: true
    )
  end

  defmodule MasterInfo do
    @moduledoc false
    use Protobuf, syntax: :proto2

    @type t :: %__MODULE__{
            external_tcp_address: String.t(),
            external_tcp_port: integer,
            external_http_address: String.t(),
            external_http_port: integer,
            external_secure_tcp_address: String.t(),
            external_secure_tcp_port: integer
          }

    defstruct external_tcp_address: "",
              external_tcp_port: 0,
              external_http_address: "",
              external_http_port: 0,
              external_secure_tcp_address: nil,
              external_secure_tcp_port: nil

    field(:external_tcp_address, 1, required: true, type: :string)
    field(:external_tcp_port, 2, required: true, type: :int32)
    field(:external_http_address, 3, required: true, type: :string)
    field(:external_http_port, 4, required: true, type: :int32)
    field(:external_secure_tcp_address, 5, optional: true, type: :string)
    field(:external_secure_tcp_port, 6, optional: true, type: :int32)
  end

  defmodule NotHandled do
    @moduledoc false
    use Protobuf, syntax: :proto2

    @type t :: %__MODULE__{
            reason: NotHandled.NotHandledReason.t(),
            additional_info: binary
          }

    defstruct reason: :NotReady,
              additional_info: nil

    field(:reason, 1,
      required: true,
      type: NotHandled.NotHandledReason,
      enum: true
    )

    field(:additional_info, 2, optional: true, type: :bytes)
  end

  defmodule ScavengeDatabase do
    @moduledoc false
    use Protobuf, syntax: :proto2

    @type t :: %__MODULE__{}

    defstruct []
  end

  defmodule ScavengeDatabaseCompleted do
    @moduledoc false
    use Protobuf, syntax: :proto2

    @type t :: %__MODULE__{
            result: ScavengeDatabaseCompleted.ScavengeResult.t(),
            error: String.t(),
            total_time_ms: integer,
            total_space_saved: integer
          }

    defstruct result: :Success,
              error: nil,
              total_time_ms: 0,
              total_space_saved: 0

    field(:result, 1,
      required: true,
      type: ScavengeDatabaseCompleted.ScavengeResult,
      enum: true
    )

    field(:error, 2, optional: true, type: :string)
    field(:total_time_ms, 3, required: true, type: :int32)
    field(:total_space_saved, 4, required: true, type: :int64)
  end

  defmodule IdentifyClient do
    @moduledoc false
    use Protobuf, syntax: :proto2

    @type t :: %__MODULE__{
            version: integer,
            connection_name: String.t()
          }

    defstruct version: 0,
              connection_name: nil

    field(:version, 1, required: true, type: :int32)
    field(:connection_name, 2, optional: true, type: :string)
  end

  defmodule ClientIdentified do
    @moduledoc false
    use Protobuf, syntax: :proto2

    @type t :: %__MODULE__{}

    defstruct []
  end
end
