#!/usr/bin/env bats

load "$BATS_PATH/load.bash"
load "$PWD/hooks/lib/cloudrc"

@test "parse array" {
  export ARRAY_VALUES_0=a
  export ARRAY_VALUES_1=b
  export ARRAY_VALUES_2=c

  IFS=" " read -r -a values < <(buildkite::readArray ARRAY_VALUES_[0-9]+)

  assert_equal "${values[0]}" "a"
  assert_equal "${values[1]}" "b"
  assert_equal "${values[2]}" "c"
}

@test "run k6 test with mandatory arguments should succeed" {
  export BUILDKITE_PLUGIN_K6_DURATION="2m"
  export BUILDKITE_PLUGIN_K6_SIMULATION_FILE="./smoke.js"
  export BUILDKITE_PLUGIN_K6_QUEUE="myqueue"
  export BUILDKITE_BUILD_ID="ABCDE1234"

  stub buildkite-agent \
       "pipeline upload ./step.yaml : echo 'pipeline uploaded'"

  stub docker-compose \
       "--version : echo 'docker-compose version 12345'"


  run "$PWD/hooks/command"

  assert_output --partial " - ./smoke.js"
  assert_output --partial "version: '3.4'"
  assert_output --partial " - K6_DURATION=2m"
  assert_output --partial "pipeline uploaded"
  assert_output --partial "agents: queue=myqueue"
  assert_output --partial "concurrency: 1"
  assert_output --partial "concurrency_group: ABCDE1234"
  assert_output --partial "docker-compose -f k6-docker-compose.yaml run --rm k6"
  refute_output --partial " - K6_CLOUFLARE_ACCESS_CLIENT_ID"
  refute_output --partial " - K6_CLOUFLARE_ACCESS_CLIENT_SECRET"
  assert_success

  unstub buildkite-agent
  unstub docker-compose
}

@test "run k6 with custom environment variables should succeed" {
  export BUILDKITE_PLUGIN_K6_DURATION="2m"
  export BUILDKITE_PLUGIN_K6_SIMULATION_FILE="./smoke.js"
  export BUILDKITE_PLUGIN_K6_QUEUE="myqueue"
  export BUILDKITE_PLUGIN_K6_ENVIRONMENT_VARIABLES_0_NAME="MY_CUSTOM_ENV_VAR"
  export BUILDKITE_PLUGIN_K6_ENVIRONMENT_VARIABLES_0_VALUE="APT"
  export BUILDKITE_PLUGIN_K6_ENVIRONMENT_VARIABLES_1_NAME="IPSOM"
  export BUILDKITE_PLUGIN_K6_ENVIRONMENT_VARIABLES_2_NAME="CUSTOM_VAR"
  export BUILDKITE_PLUGIN_K6_ENVIRONMENT_VARIABLES_2_VALUE="CUSTOM_VALUE"
  export BUILDKITE_BUILD_ID="ABCDE1234"

  stub buildkite-agent \
       "pipeline upload ./step.yaml : echo 'pipeline uploaded'"

  stub docker-compose \
       "--version : echo 'docker-compose version 12345'"


  run "$PWD/hooks/command"

  assert_output --partial " - ./smoke.js"
  assert_output --partial "version: '3.4'"
  assert_output --partial "pipeline uploaded"
  assert_output --partial "agents: queue=myqueue"
  assert_output --partial "concurrency: 1"
  assert_output --partial "concurrency_group: ABCDE1234"
  assert_output --partial "docker-compose -f k6-docker-compose.yaml run --rm k6"
  assert_output --partial " - K6_DURATION=2m"
  assert_output --partial " - MY_CUSTOM_ENV_VAR=APT"
  assert_output --partial " - CUSTOM_VAR=CUSTOM_VALUE"
  assert_output --partial " - IPSOM"
  refute_output --partial " - IPSOM="
  assert_success

  unstub buildkite-agent
  unstub docker-compose
}


@test "run k6 with provided concurrency parameters should succeed" {
  export BUILDKITE_PLUGIN_K6_DURATION="2m"
  export BUILDKITE_PLUGIN_K6_SIMULATION_FILE="./smoke.js"
  export BUILDKITE_PLUGIN_K6_QUEUE="myqueue"
  export BUILDKITE_PLUGIN_K6_CONCURRENCY="10"
  export BUILDKITE_PLUGIN_K6_CONCURRENCY_GROUP="my-concurrency-group"
  export BUILDKITE_BUILD_ID="ABCDE1234"

  stub buildkite-agent \
       "pipeline upload ./step.yaml : echo 'pipeline uploaded'"

  stub docker-compose \
       "--version : echo 'docker-compose version 12345'"

  run "$PWD/hooks/command"

  assert_output --partial "concurrency: 10"
  assert_output --partial "concurrency_group: my-concurrency-group"
  assert_success

  unstub buildkite-agent
  unstub docker-compose
}

@test "provide cloudflare access credentials should succeed" {
  export BUILDKITE_PLUGIN_K6_DURATION="2m"
  export BUILDKITE_PLUGIN_K6_SIMULATION_FILE="./smoke.js"
  export BUILDKITE_PLUGIN_K6_QUEUE="myqueue"
  export BUILDKITE_PLUGIN_K6_CLOUDFLARE_ACCESS_CLIENT_SECRET="/path/to/secret"
  export BUILDKITE_BUILD_ID="ABCDE1234"

  stub buildkite-agent \
       "pipeline upload ./step.yaml : echo 'pipeline uploaded'"

  stub docker-compose \
       "--version : echo 'docker-compose version 12345'"

  stub aws \
       "secretsmanager get-secret-value --secret-id /path/to/secret : echo 'payload'"

  stub jq \
       "-r '.SecretString | fromjson | .\"CF-Access-Client-ID\"' : echo 'client-id'" \
       "-r '.SecretString | fromjson | .\"CF-Access-Client-Secret\"' : echo 'client-secret'"

  run "$PWD/hooks/command"

  assert_output --partial " - K6_CLOUDFLARE_ACCESS_CLIENT_ID"
  assert_output --partial " - K6_CLOUDFLARE_ACCESS_CLIENT_SECRET"
  assert_success

  unstub buildkite-agent
  unstub jq
  unstub aws
  unstub docker-compose
}

