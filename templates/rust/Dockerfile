FROM rust:1.83-slim AS builder

WORKDIR /app
COPY . .
RUN cargo build --release --bin lab_cli

FROM debian:bookworm-slim AS runtime

RUN addgroup --system app && adduser --system --ingroup app app
COPY --from=builder /app/target/release/lab_cli /usr/local/bin/lab_cli
USER app

ENTRYPOINT ["lab_cli"]
