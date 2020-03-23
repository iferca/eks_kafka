import setuptools


with open("README.md") as fp:
    long_description = fp.read()


setuptools.setup(
    name="eks_kafka",
    version="0.0.1",

    description="AWS EKS + Kafka POC stack",
    long_description=long_description,
    long_description_content_type="text/markdown",

    author="Israel Fdez.",

    package_dir={"": "eks_kafka"},
    packages=setuptools.find_packages(where="eks_kafka"),

    install_requires=[
        "aws-cdk.core",
        "aws-cdk.aws-eks"
    ],

    python_requires=">=3.6",

    classifiers=[
        "Development Status :: 4 - Beta",

        "Intended Audience :: Developers",

        "License :: OSI Approved :: Apache Software License",

        "Programming Language :: JavaScript",
        "Programming Language :: Python :: 3 :: Only",
        "Programming Language :: Python :: 3.6",
        "Programming Language :: Python :: 3.7",
        "Programming Language :: Python :: 3.8",

        "Topic :: Software Development :: Code Generators",
        "Topic :: Utilities",

        "Typing :: Typed",
    ],
)
