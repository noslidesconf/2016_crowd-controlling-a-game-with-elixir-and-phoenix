defmodule PassTheChain.Presence do
  use Phoenix.Presence,
    otp_app: :pass_the_chain,
    pubsub_server: PassTheChain.PubSub
end
