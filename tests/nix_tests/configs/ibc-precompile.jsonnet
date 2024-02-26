local config = import 'ibc.jsonnet';

config {
  'anryton_9000-1'+: {
    genesis+: {
      app_state+: {
        feemarket+: {
          params+: {
            no_base_fee: false,
            base_fee: '100000000000',
          },
        },
      },
    },
  },
}
