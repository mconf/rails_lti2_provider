# AGENTS.md

Mconf fork of `rails_lti2_provider`: the Rails engine behind bbb-lti-broker's LTI tools, launches and registrations. Mconf's work lives on branch `elos`; the broker pins a revision of it in its `Gemfile.lock`, so a change here reaches the broker only after a `bundle update rails_lti2_provider --conservative` there.

Placeholder: this repo does not follow the Mconf repository baseline yet (no Makefile, no pre-commit hook, no CI). Standards: https://github.com/mconf/mpedia/tree/main/development

## Checks

```bash
bundle exec rubocop
bundle exec rspec
```

## Logs never carry credentials

`check_launch` sees the tool's shared secret. Logs end up in shared storage, so a credential in a log line is a leaked credential.

- Never interpolate the shared secret or any other credential into a log line. Log ids and keys instead.
- The launch params stay in the log: in LTI 1.1 they hold no credential (the OAuth signature is single-use), and support needs them, the e-mail included, to correlate launches. Once logged, the log retention policy takes care of the personal data.
