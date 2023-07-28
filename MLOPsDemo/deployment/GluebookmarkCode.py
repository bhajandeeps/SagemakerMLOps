import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

args = getResolvedOptions(sys.argv, ["JOB_NAME","S3_SOURCE", "S3_DEST","src_context","tgt_context"])
sc = SparkContext()
glueContext = GlueContext(sc)
glueContext.purge_s3_path(args["S3_DEST"], options={"retentionPeriod":0})#purge target for each execution
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)

# Script generated for node S3 bucket
S3bucket_node1 = glueContext.create_dynamic_frame.from_options(
    format_options={"quoteChar": '"', "withHeader": False, "separator": ","},
    connection_type="s3",
    format="csv",
    connection_options={
        "paths": [args["S3_SOURCE"]],
        "recurse": True,
    },
    transformation_ctx=args["src_context"],
)

# # Script generated for node Apply Mapping
# ApplyMapping_node1648633086293 = ApplyMapping.apply(
#     frame=S3bucket_node1,
#     mappings=[
#         ("col0", "long", "col0", "long"),
#         ("col1", "string", "col1", "string"),
#         ("col2", "choice", "col2", "choice"),
#         ("col3", "choice", "col3", "choice"),
#         ("col4", "choice", "col4", "choice"),
#         ("col5", "string", "col5", "string"),
#         ("col6", "choice", "col6", "choice"),
#     ],
#     transformation_ctx="ApplyMapping_node1648633086293",
# )

# Script generated for node S3 bucket
S3bucket_node3 = glueContext.getSink(
    path=args["S3_DEST"],
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=[],
    enableUpdateCatalog=True,
    transformation_ctx=args["tgt_context"],
)
S3bucket_node3.setFormat("csv")
S3bucket_node3.writeFrame(S3bucket_node1)
job.commit()
