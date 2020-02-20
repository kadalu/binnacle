from setuptools import setup


setup(
    name="binnacle",
    version="0.1.0",
    packages=["binnacle"],
    include_package_data=True,
    package_data={'binnacle': ['*.rc']},
    install_requires=[""],
    entry_points={
        "console_scripts": [
            "binnacle = binnacle.main:main",
        ]
    },
    platforms="linux",
    zip_safe=False,
    author="Kadalu.IO",
    author_email="support@kadalu.io",
    description="Binnacle - Distributed Test Framework",
    license="Apache-2.0",
    keywords="kadalu, testing, distributed",
    url="https://github.com/kadalu/binnacle",
    long_description="""
    Distributed Test Framework
    """,
    classifiers=[
        "Development Status :: 4 - Beta",
        "Topic :: Utilities",
        "Environment :: Console",
        "License :: OSI Approved :: Apache Software License",
        "Operating System :: POSIX :: Linux",
        "Programming Language :: Python",
        "Programming Language :: Python :: 3 :: Only",
    ],
)
