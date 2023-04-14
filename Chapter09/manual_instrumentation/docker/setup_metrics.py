# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

import logging
import os

from opentelemetry import metrics
from opentelemetry.exporter.otlp.proto.grpc.metric_exporter import OTLPMetricExporter
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.resources import SERVICE_NAME, Resource
from opentelemetry.sdk.metrics.export import PeriodicExportingMetricReader

logger = logging.getLogger(__name__)

# Setup Global Metric Provider

reader = PeriodicExportingMetricReader(
    exporter=OTLPMetricExporter(),
    export_interval_millis=5000
)

metrics.set_meter_provider(MeterProvider(metric_readers=[reader]))

meter = metrics.get_meter("aws-otel", "1.0")

# Setup Metric Components

apiBytesSentMetricName = "apiBytesSent"
latencyMetricName = "latency"

if "INSTANCE_ID" in os.environ:
    instanceId = os.environ["INSTANCE_ID"]
    if not instanceId.strip() == "":
        latencyMetricName += "_" + instanceId
        apiBytesSentMetricName += "_" + instanceId

apiBytesSentCounter = meter.create_counter(
    apiBytesSentMetricName, unit="1", description="API request load sent in bytes"
)

apiLatencyRecorder = meter.create_histogram(
    latencyMetricName, unit="ms", description="API latency time"
)