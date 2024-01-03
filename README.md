<img src="https://github.com/sunbeam-labs/sunbeam/blob/stable/docs/images/sunbeam_logo.gif" width=120, height=120 align="left" />

# sbx_mgv

<!-- Badges start -->
[![Tests](https://github.com/Ulthran/sbx_mgv/actions/workflows/tests.yml/badge.svg)](https://github.com/Ulthran/sbx_mgv/actions/workflows/tests.yml)
[![Super-Linter](https://github.com/Ulthran/sbx_mgv/actions/workflows/linters.yml/badge.svg)](https://github.com/Ulthran/sbx_mgv/actions/workflows/linters.yml)
<!-- Badges end -->


## Introduction

sbx_mgv is a [sunbeam](https://github.com/sunbeam-labs/sunbeam) extension for classifying viral sequences. This pipeline uses [MEGAHIT](https://github.com/voutcn/megahit) for assembly of contigs and [MGV](https://github.com/snayfach/MGV) for virus classification.

N.B. If using Megahit for assembly, this extension requires also having sbx_assembly installed.

### Installation

```
sunbeam extend https://github.com/Ulthran/sbx_mgv.git
```

## Running

Run with sunbeam on the target `all_mgv`,

```
sunbeam run --profile /path/to/project/ all_mgv
```

### Options for config.yml

There are currently no config options for this extension.

## Legacy Installation

```
git clone https://github.com/Ulthran/sbx_mgv.git extensions/sbx_mgv
cd extensions/sbx_mgv
cat config.yml >> /path/to/sunbeam_config.yml
```

## Issues with pipeline

Please post any issues with this extension [here](https://github.com/Ulthran/sbx_mgv/issues).

