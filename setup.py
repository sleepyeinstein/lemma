from setuptools import setup
setup(
    name='lemmacli',
    version='0.1.0',
    packages=['lemma'],
    description='Run commandline tools on AWS Lambda',
    url='https://github.com/defparam/lemma',
    author='defparam',
    license='Apache 2.0',
    include_package_data=True,
    install_requires=[
        "requests",
    ],
    entry_points={
        'console_scripts': [
            'lemma=lemma.__main__:main',
        ],
    },
    classifiers=[
        'Programming Language :: Python :: 3',
        'Operating System :: OS Independent',
    ],
    python_requires='>=3.6',
)
