import sys
from pyspark.sql import SparkSession

DEFAULT_UPPER_BOUND = 1000

if __name__ == "__main__":
    """
        Usage: example [upper bound]
    """
    spark = SparkSession\
        .builder\
        .appName("ExampleGrandataSparkSubmit")\
        .getOrCreate()

    upperBound = int(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_UPPER_BOUND
    
    my_range = spark.range(upperBound).toDF("number")
    divisBy5 = my_range.where("number % 5 = 0")
    print(
        120*"=",
        f"Total number of multiples of 5 from 0 to {upperBound}: {divisBy5.count()}",
        120*"=",
        sep="\n"
    )
    
    spark.stop()