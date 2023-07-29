import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

args = getResolvedOptions(sys.argv, ["JOB_NAME","S3_SOURCE", "S3_DEST","S3_PART_DEST","src_context","tgt_context","part_tgt_context"])
sc = SparkContext()
glueContext = GlueContext(sc)
glueContext.purge_s3_path(args["S3_DEST"], options={"retentionPeriod":0})#purge target for each execution
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)

# Script generated for node S3 bucket
S3bucket_node1 = glueContext.create_dynamic_frame.from_options(
    format_options={"multiline": False},
    connection_type="s3",
    format="json",
    connection_options={
        "paths": [
            args["S3_SOURCE"]
        ],
        "recurse": True,
    },
    transformation_ctx=args["src_context"],
)

# Script generated for node ApplyMapping
ApplyMapping_node2 = ApplyMapping.apply(
    frame=S3bucket_node1,
    mappings=[
        (
            "captureData.endpointInput.observedContentType",
            "string",
            "captureData.endpointInput.observedContentType",
            "string",
        ),
        (
            "captureData.endpointInput.mode",
            "string",
            "captureData.endpointInput.mode",
            "string",
        ),
        (
            "captureData.endpointInput.data",
            "string",
            "captureData.endpointInput.data",
            "string",
        ),
        (
            "captureData.endpointInput.encoding",
            "string",
            "captureData.endpointInput.encoding",
            "string",
        ),
        (
            "captureData.endpointOutput.observedContentType",
            "string",
            "captureData.endpointOutput.observedContentType",
            "string",
        ),
        (
            "captureData.endpointOutput.mode",
            "string",
            "captureData.endpointOutput.mode",
            "string",
        ),
        (
            "captureData.endpointOutput.data",
            "string",
            "captureData.endpointOutput.data",
            "string",
        ),
        (
            "captureData.endpointOutput.encoding",
            "string",
            "captureData.endpointOutput.encoding",
            "string",
        ),
        ("eventMetadata.eventId", "string", "eventMetadata.eventId", "string"),
        (
            "eventMetadata.inferenceTime",
            "string",
            "eventMetadata.inferenceTime",
            "string",
        ),
        (
            "eventMetadata.inferenceId",
            "string",
            "eventMetadata.inferenceId",
            "string",
        ),
        ("eventVersion", "string", "eventVersion", "string"),
    ],
    transformation_ctx="ApplyMapping_node2",
)

# Script generated for node S3 bucket
S3bucket_node3 = glueContext.write_dynamic_frame.from_options(
    frame=ApplyMapping_node2,
    connection_type="s3",
    format="json",
    connection_options={
        "path": args["S3_DEST"],
        "partitionKeys": [],
    },
    transformation_ctx=args["tgt_context"],
)
# Script generated for node S3 bucket
S3bucket_partition = glueContext.write_dynamic_frame.from_options(
    frame=ApplyMapping_node2,
    connection_type="s3",
    format="json",
    connection_options={
        "path": args["S3_PART_DEST"],
        "partitionKeys": [],
    },
    transformation_ctx=args["part_tgt_context"],
)

job.commit()
