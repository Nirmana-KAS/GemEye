"""S3 image storage under the environment prefix. The bucket stays private;
clients get short-lived presigned GET URLs. Objects use SSE-S3."""
import boto3
from botocore.config import Config
from botocore.exceptions import ClientError

PRESIGN_SECONDS = 600


class Storage:
    def __init__(self, bucket, region, access_key_id=None, secret_access_key=None, prefix=""):
        self.bucket = bucket
        self.prefix = prefix
        self.s3 = boto3.client(
            "s3", region_name=region, endpoint_url=f"https://s3.{region}.amazonaws.com",
            aws_access_key_id=access_key_id, aws_secret_access_key=secret_access_key,
            config=Config(signature_version="s3v4", s3={"addressing_style": "virtual"},
                          retries={"max_attempts": 3, "mode": "standard"}))

    def grading_key(self, uid, grading_id, ext="jpg"):
        return f"{self.prefix}gradings/{uid}/{grading_id}.{ext}"

    def _check(self, key):
        if not key.startswith(self.prefix):
            raise ValueError("key outside the environment prefix")

    def put(self, key, data, content_type):
        self._check(key)
        self.s3.put_object(Bucket=self.bucket, Key=key, Body=data, ContentType=content_type,
                           ServerSideEncryption="AES256")

    def get(self, key):
        self._check(key)
        return self.s3.get_object(Bucket=self.bucket, Key=key)["Body"].read()

    def delete(self, key):
        self._check(key)
        self.s3.delete_object(Bucket=self.bucket, Key=key)

    def exists(self, key):
        self._check(key)
        try:
            self.s3.head_object(Bucket=self.bucket, Key=key)
            return True
        except ClientError as e:
            if e.response.get("Error", {}).get("Code") in ("404", "NoSuchKey", "NotFound"):
                return False
            raise

    def presigned_get(self, key, expires=PRESIGN_SECONDS):
        self._check(key)
        return self.s3.generate_presigned_url(
            "get_object", Params={"Bucket": self.bucket, "Key": key}, ExpiresIn=expires)

    def delete_prefix(self, sub_prefix):
        """Deletes every object under prefix + sub_prefix; returns the count."""
        full = self.prefix + sub_prefix
        n = 0
        for page in self.s3.get_paginator("list_objects_v2").paginate(Bucket=self.bucket, Prefix=full):
            keys = [{"Key": o["Key"]} for o in page.get("Contents", [])]
            if keys:
                self.s3.delete_objects(Bucket=self.bucket, Delete={"Objects": keys, "Quiet": True})
                n += len(keys)
        return n
