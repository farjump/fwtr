# About

An open place to share compliance results of board's firmwares with BIOS, UEFI, ACPI,
Multiboot... Anything your software (bootloader, OS...) may rely on.

Every non ad hoc operating system highly relies on standardized interfaces that
the firmware and the bootloader(s) are largely responsible for (e.g., the
physical memory mapping, EFI services). Non compliant firmwares are likely to
cause serious problems and undefined behaviours (e.g., bootloader errors, power
management issues). Since firmwares of proprietary boards cannot be replaced
with better ones, you could end up with an unusable board. So far, you can only
hope and cross your fingers to purchase a board with a firmware correctly
implementing the features your OS expects.

Every firmware developer should provide these results. Until then, feel free to share with the
community, especially if your results show important errors... Standard testing tools such as
Firmware Test Suite ([FWTS]) or Linux UEFI Validation ([LUV]) are freely available and allow you to
test your firmware with a live CD/USB very simply.


# Consulting Results

This repository is meant to be very simple and as straightforward as possible. Results are
catalogued per system vendors, system names, motherboard names, etc. But you should use a search
engine (e.g., GitHub's) when looking for specific results.

Use http://rawgit.com/ to render html results without cloning the repository ([demo](https://cdn.rawgit.com/farjump/fwtr/v1.0.0/intel/nuc/de3815tykh/intel/tybyt10h.86a.0046.2015.1014.1057/fwts/20160206_220323/results.html)).

To avoid dead links, a new version tag is released every time new results are merged. Allowing
you to share permalinks by browsing this repository by tags instead of moving branch heads such as
`master`.


# Testing your firmware

Live images are available and are the easiest way to test your firmware without modifying your OS setup.
Simply download it, copy it on a USB key, and boot from it (telling your firmware to do so). Please
follow the official documentation of the tool you chose.

## Ubuntu's Firmware Test Suite (FWTS) - recommended

Allows to test BIOS, UEFI and ACPI interfaces.

The [Firmware Test Suite] is officially
[recommended by the UEFI Board of Directors](http://uefi.org/testtools) for ACPI Self-Certification
Test.

### Live Image

The easiest way to run it is using [the live image](https://wiki.ubuntu.com/FirmwareTestSuite/FirmwareTestSuiteLive).
It does everything for you: from running the tools according to the test suites you selected, to saving the results
in the key. You can then send the result with a pull request ;)

### Command line

Install or compile [FWTS] from the [sources](http://kernel.ubuntu.com/git/hwe/fwts.git).

Usage example:
```sh
# root privileges required
$ mkdir my-test && cd my-test
$ fwts -d -f --log-type plaintext,html --batch
# ask fwts to run every non-interactive tests available (--batch), dump firmware log files (-d),
# log the results in HTML (--log-type), and recreate new logs (-f).
$ ls
results.html acpi.log lspcidump.log dmesg.log ...
```

Refer to [the reference]([https://wiki.ubuntu.com/FirmwareTestSuite/Reference]) for more details about
available test suites.


## Intel's Linux UEFI Validation (LUV)

[Linux UEFI Validation]. Similar to [FWTS].

### Live Image

The easiest way to run it is also using [the live image](https://01.org/linux-uefi-validation/downloads/luv-live-image).
It does everything for you: from running the tool, to saving the results in the key.
You can then send the resulting directory with a pull request ;)


# Contributing - Sharing results

## Expected Results

Please read the section `Testing your firmware` to run your tests and include:

- HTML results for easier reading (using rawgit, as already explained).
- Plain text results to allow diffing between test variants.
- As much logs as you want, especially if you are reporting bugs to firmware teams.
- Remove serial numbers from your logs.


## Storing Results

The shell script `scripts/fwtr.sh` will guide you to store your results.
A POSIX shell and GNU Awk are required.

```text
$ ./scripts/fwtr.sh --help
Usage: ./scripts/fwtr.sh [--help] <command> <args>

COMMANDS
  add [<options>] <logs>...
    Add new test results in the repository. Retrieve data from the logs and
    store them accordingly.

    Options:
      --dry-run
        Do not execute the commands adding the results in the repository.
        Useful to see what would happen and what can be retrieved from the logs.

      --test-id=ID
        Force the test ID. Default is the test date in the logs.

      --system-vendor=NAME
        Force the system vendor name. Default is retrieved from the
        BIOS Information Table in the logs.

      --bios-vendor=NAME
        Force the BIOS vendor name.

      --product-name=NAME
        Force the product name.

      --board-name=NAME
        Force the board name.

      --bios-version=NAME
        Force the BIOS version.
```

It applies the following template to the BIOS Information table contained in your result logs:

```text
<system-vendor>/<product-name>/<board-name>/<bios-vendor>/<bios-version>/<tool-name>/<test-id>
```

If some data is missing or wrong, options are available to force their values. You are greatly
advised to use `--dry-run` to see what happens.

Since this tool needs to be further validated, the script is interactive and asks you to review
retrieved data.

## Writing the `README.md`

A `README.md` template is created by the tool. Please describe as much as possible the BIOS
settings that may influence your results (e.g., UEFI boot disabled). Note that tools like [FWTS]
allow you to unselect test suites so that you only cover what your settings enable. [FWTS] is also
generally able to skip disabled features.

## Examples

### Results with a good BIOS Information table

`fwtr.sh add` don't need further options with results from a motherboard whose BIOS Information
table is correctly programmed.

```text
$ ./scripts/fwtr.sh add my_dell_inspiron_3521_test/results.log
fwtr add: probing the result format...
fwtr add: `fwts` version `V16.01.00` detected.
fwtr add: retrieving BIOS informations...

fwtr add: Collected data:
fwtr add: BIOS Vendor:       dell
fwtr add: BIOS Version:      A12
fwtr add: BIOS Release Date: 10/25/2013
fwtr add: Board Name:        0010T1
fwtr add: Board Version:     A00
fwtr add: Product Name:      Inspiron 3521
fwtr add: Product Version:   A12
fwtr add: System Vendor:     dell

fwtr add: Test ID:                       20160209_130610
fwtr add: Source Test Results Path:      my_dell_inspiron_3521_test
fwtr add: Destination Test Results Path: ./scripts/../dell/inspiron-3521/0010t1/dell/a12/fwts/20160209_130610

fwtr add: please review previous logs before continuing.
fwtr add: options are available in order to correct wrong informations by forcing values.
fwtr add: continue? (C-c or C-d to exit)
[...]
```

### Results with an incomplete or wrong BIOS Information table

`fwtr.sh add` should not fail but it won't be able to end with a correct result. If mandatory
values are missing, `fwtr.sh add` should report you the error. But if the table contains wrong
informations, only you can correct it by using `fwtr.sh add` options.

Here is an example of a table with dummy entries (probably read from an uninitialized ROM):

```text
$ ./scripts/fwtr.sh add --dry-run my_intel_nuc_de3815tykhe/results.html
fwtr add: probing the result format...
fwtr add: `fwts` version `V16.01.00` detected.
fwtr add: retrieving BIOS informations...
ERROR: unknown vendor name `���������������������������������`
       please add your new vendor name in `to_vendor_id()` function

fwtr add: Collected data:
fwtr add: BIOS Vendor:       intel
fwtr add: BIOS Version:      TYBYT10H.86A.0046.2015.1014.1057
fwtr add: BIOS Release Date: 10/14/2015
fwtr add: Board Name:        DE3815TYKH
fwtr add: Board Version:     H26998-401
fwtr add: Product Name:      ���������������������������������
fwtr add: Product Version:   ���������������������������������
fwtr add: System Vendor:     error

fwtr add: Test ID:                       20160206_220323
fwtr add: Source Test Results Path:      my_intel_nuc_de3815tykhe
fwtr add: Destination Test Results Path: ./scripts/../error/���������������������������������/de3815tykh/intel/tybyt10h.86a.0046.2015.1014.1057/fwts/20160206_220323

fwtr add: please review previous logs before continuing.
fwtr add: options are available in order to correct wrong informations by forcing values.
fwtr add: continue? (C-c or C-d to exit)
<C-c keystroke>
```

You can see this table has some uninitialized entries. Values need to be provided manually:

```text
$ ./scripts/fwtr.sh add --system-vendor intel --product-name nuc my_intel_nuc_de3815tykhe/results.html
fwtr add: probing the result format...
fwtr add: `fwts` version `V16.01.00` detected.
fwtr add: retrieving BIOS informations...
ERROR: unknown vendor name `���������������������������������`
       please add your new vendor name in `to_vendor_id()` function

fwtr add: Collected data:
fwtr add: BIOS Vendor:       intel
fwtr add: BIOS Version:      TYBYT10H.86A.0046.2015.1014.1057
fwtr add: BIOS Release Date: 10/14/2015
fwtr add: Board Name:        DE3815TYKH
fwtr add: Board Version:     H26998-401
fwtr add: Product Name:      nuc [forced]
fwtr add: Product Version:   ���������������������������������
fwtr add: System Vendor:     intel [forced]

fwtr add: Test ID:                       20160206_220323
fwtr add: Source Test Results Path:      my_intel_nuc_de3815tykhe
fwtr add: Destination Test Results Path: ./scripts/../intel/nuc/de3815tykh/intel/tybyt10h.86a.0046.2015.1014.1057/fwts/20160206_220323

fwtr add: please review previous logs before continuing.
fwtr add: options are available in order to correct wrong informations by forcing values.
fwtr add: continue? (C-c or C-d to exit)
[...]
```

Forcing values won't avoid their parsing from the logs. Values are only **overwritten** after
the parsing. This is why error messages from text sanitizers are still present.

## Still need help?

If things are still unclear, place your result folder wherever you think it should be using
`fwtr.sh add` and create a pull request that will be reviewed and reworked before merging
if required.


# License

<p xmlns:dct="http://purl.org/dc/terms/">
  <a rel="license"
     href="http://creativecommons.org/publicdomain/zero/1.0/">
    <img src="https://licensebuttons.net/p/zero/1.0/88x31.png" style="border-style: none;" alt="CC0" />
  </a>
  <br />
  To the extent possible under law,
  <a rel="dct:publisher"
     href="https://github.com/farjump/fwtr">
    <span property="dct:title">farjump</span></a>
  has waived all copyright and related or neighboring rights to
  <span property="dct:title">the Open Database of Firmware Test Results</span>.
</p>

[FWTS]: https://wiki.ubuntu.com/FirmwareTestSuite
[Firmware Test Suite]: https://wiki.ubuntu.com/FirmwareTestSuite
[LUV]: https://01.org/linux-uefi-validation
[Linux UEFI Validation]: https://01.org/linux-uefi-validation
