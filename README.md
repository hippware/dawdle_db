# DawdleDB

DawdleDB uses Dawdle and SQS to capture change notifications from PostgreSQL.

## Installation

The package can be installed by adding `dawdle_db` to your list of
dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:dawdle_db, "~> 0.8.0"}
  ]
end
```

Documentation can be found at [https://hexdocs.pm/dawdle_db](https://hexdocs.pm/dawdle_db).

## Usage

DawdleDB can be run in either watcher mode or listener mode. In watcher mode it
captures PostgreSQL notifications and encodes them into an Elixir struct which
is then posted to SQS. In listener mode, the events are pulled out of SQS and
handed off to handlers for processing.

For best results, there should only be one instance of DawdleDB running in
watcher mode; though you can have many instances running in listener mode. In
normal use, DawdleDB can handle this internally. You can start the watcher from
your application's `start` callback and DawdleDB will use [Swarm] to ensure that there is only one instance of the watcher running. The function
`DawdleDB.start_watcher/1` takes the name of your Ecto repo and will use the
repo's configuration to connect to the database.

```elixir
defmodule MyApp do
  use Application

  def start(_type, _args) do
    children = [
      # ...
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    sup = Supervisor.start_link(children, opts)

    DawdleDB.start_watcher(MyApp.Repo)

    sup
  end
end
```

If you want to run the DawdleDB watcher in a separate application, a model
application that can be deployed as-is or customized for a particular
application can be found at https://github.com/hippware/dawdle_db_watcher.


### Initial setup

DawdleDB relies on database triggers to fire the appropriate notifications.
There are helpers defined in `DawdleDB.Migration` to simplify initial setup
and defining the triggers.

For example, if you already have a `users` table and you wish to recieve
notifications on insert, update, and delete, you could create a migration like
the following:

```elixir
defmodule MyApp.DawdleDBSetup do
  use Ecto.Migration

  import DawdleDB.Migration

  def up do
    create_watcher_events_table()
    update_notify("users", [:insert, :update, :delete])
  end

  def down do
    remove_notify("users", [:insert, :update, :delete])
    drop_watcher_events_table()
  end
end
```

### Handlers

Once the watcher events table has been created, and triggers have been setup,
define a handler based on `DawdleDB.Handler`.

```elixir
defmodule MyApp.UserHandler do
  use DawdleDB.Handler, type: MyApp.User

  alias MyApp.User

  def handle_insert(%User{} = new) do
    # Do something when a user is created
    :ok
  end

  def handle_update(%User{} = new, %User{} = old) do
    # Do something when a user is updated
    :ok
  end

  def handle_delete(%User{} = old) do
    # Do something when a user is deleted
    :ok
  end
end
```

[Swarm]: https://github.com/bitwalker/swarm
