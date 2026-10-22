# abap-accx-test

*[Deutsch](#deutsch) below.*

Test data setup of [Access Explorer (ACCX)](https://github.com/MDJoerg/abap-accx-base) for
development and QA. ABAP package `ZACCX_TEST`. **Not for production systems.**

It creates test roles (`ZACCX_T_*`) and the data the integration tests of ACCX need, so that
the tools can be checked against known roles. It uses the write plugin
[abap-accx-plugin-admin](https://github.com/MDJoerg/abap-accx-plugin-admin) to build the roles.

## Install

1. Install **abap-accx-base** (`ZACCX`), **abap-accx-plugin-admin** (`ZACCX_PLG_ADMIN`) and an adapter.
2. Pull this repository into package `ZACCX_TEST` with abapGit.
3. Run class `ZCL_ACCX_TEST_SETUP` with F9 in ADT to create the test roles.

More (tools, security, how the packages fit together) is documented in
**[abap-accx-base](https://github.com/MDJoerg/abap-accx-base)**.

## Deutsch

Testdaten-Setup von [Access Explorer (ACCX)](https://github.com/MDJoerg/abap-accx-base) für
Entwicklung und QS. ABAP-Paket `ZACCX_TEST`. **Nicht für Produktivsysteme.**

Es legt Testrollen (`ZACCX_T_*`) und die Daten an, die die Integrationstests von ACCX brauchen,
damit die Werkzeuge gegen bekannte Rollen geprüft werden können. Zum Aufbau der Rollen nutzt es das
Schreib-Plugin [abap-accx-plugin-admin](https://github.com/MDJoerg/abap-accx-plugin-admin).

### Installation

1. **abap-accx-base** (`ZACCX`), **abap-accx-plugin-admin** (`ZACCX_PLG_ADMIN`) und einen Adapter installieren.
2. Dieses Repository mit abapGit in das Paket `ZACCX_TEST` ziehen.
3. Klasse `ZCL_ACCX_TEST_SETUP` in ADT mit F9 ausführen, um die Testrollen anzulegen.

Mehr (Tools, Sicherheit, Zusammenspiel der Pakete) steht in
**[abap-accx-base](https://github.com/MDJoerg/abap-accx-base)**.
