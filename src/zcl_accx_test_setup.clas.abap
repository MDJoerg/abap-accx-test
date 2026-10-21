"! <p class="shorttext synchronized">Access Explorer: test roles setup (F9)</p>
"! Desired state of the PFCG test roles of TESTDATEN_ACCX_A4H.md, maintained via
"! ZIF_ACCX_ROLE_WRITER (package ZACCX_PLG_ADMIN), and of the SUIM critical
"! authorization ZACCX_DEBUG used by the critical flags of explain_missing_access.
"! co_apply / co_apply_rules = abap_false (default): only the deviations are reported.
"! Users are NOT created here; the report lists them for checking.
"! <p class="shorttext synchronized">Access Explorer: test roles setup (F9)</p>
"! Desired state of the PFCG test roles of TESTDATEN_ACCX_A4H.md, maintained via
"! ZIF_ACCX_ROLE_WRITER (package ZACCX_PLG_ADMIN), and of the SUIM critical
"! authorization ZACCX_DEBUG used by the critical flags of explain_missing_access.
"! co_apply / co_apply_rules = abap_false (default): only the deviations are reported.
"! Users are NOT created here; the report lists them for checking.
"! <p class="shorttext synchronized">Access Explorer: test roles setup (F9)</p>
"! Desired state of the PFCG test roles of TESTDATEN_ACCX_A4H.md, maintained via
"! ZIF_ACCX_ROLE_WRITER (package ZACCX_PLG_ADMIN), and of the SUIM critical
"! authorization ZACCX_DEBUG used by the critical flags of explain_missing_access.
"! co_apply / co_apply_rules = abap_false (default): only the deviations are reported.
"! Users are NOT created here; the report lists them for checking.
"! <p class="shorttext synchronized">Access Explorer: test roles setup (F9)</p>
"! Desired state of the PFCG test roles of TESTDATEN_ACCX_A4H.md, maintained via
"! ZIF_ACCX_ROLE_WRITER (package ZACCX_PLG_ADMIN), and of the SUIM test data:
"! critical authorization ZACCX_DEBUG, combination ZACCX_DBG_TAB and their variants.
"! co_apply / co_apply_rules = abap_false (default): only the deviations are reported.
"! Users are NOT created here; the report lists them for checking.
"! <p class="shorttext synchronized">Access Explorer: test roles setup (F9)</p>
"! Desired state of the PFCG test roles of TESTDATEN_ACCX_A4H.md, maintained via
"! ZIF_ACCX_ROLE_WRITER (package ZACCX_PLG_ADMIN), and of the SUIM test data:
"! critical authorization ZACCX_DEBUG, combination ZACCX_DBG_TAB and their variants.
"! co_apply / co_apply_rules = abap_false (default): only the deviations are reported.
"! Users are NOT created here; the report lists them for checking.
CLASS zcl_accx_test_setup DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

    CONSTANTS co_apply TYPE abap_bool VALUE abap_false.
    CONSTANTS co_apply_rules TYPE abap_bool VALUE abap_false.

    CONSTANTS co_debug_rule TYPE auth_id VALUE 'ZACCX_DEBUG'.
    CONSTANTS co_debug_comb TYPE comb_id VALUE 'ZACCX_DBG_TAB'.
    CONSTANTS co_variant TYPE varnameca VALUE 'ZACCX_TEST'.
    CONSTANTS co_comb_variant TYPE varnamecom VALUE 'ZACCX_TEST_COMB'.

    "! Desired state of all test roles (single roles before composite roles)
    CLASS-METHODS desired_roles
      RETURNING VALUE(result) TYPE zif_accx_role_writer=>ty_role_specs.

  PRIVATE SECTION.
    DATA out TYPE REF TO if_oo_adt_classrun_out.

    METHODS write_deviations
      IMPORTING !label      TYPE string
                !deviations TYPE zif_accx_role_writer=>ty_deviations.

    METHODS report_users.

    "! SUIM test data: critical authorization 'debugging with replace' (S_DEVELOP DEBUG 02),
    "! combination with table maintenance, variants ZACCX_TEST / ZACCX_TEST_COMB.
    "! SUIM offers no API; the tables are written directly, never in production clients.
    METHODS sync_critical_rule.

ENDCLASS.

CLASS zcl_accx_test_setup IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
    me->out = out.
    DATA(writer) = CAST zif_accx_role_writer( NEW zcl_accx_role_writer( ) ).

    LOOP AT desired_roles( ) INTO DATA(spec).
      out->write( |--- { spec-name }| ).
      write_deviations( label = `plan` deviations = writer->plan( spec ) ).
      IF co_apply = abap_true.
        LOOP AT writer->apply( spec ) INTO DATA(step).
          out->write( |  { COND #( WHEN step-ok = abap_true THEN `ok    ` ELSE `FAILED` ) } { step-step }| ).
          LOOP AT step-messages INTO DATA(message).
            out->write( |         { message }| ).
          ENDLOOP.
        ENDLOOP.
        COMMIT WORK AND WAIT.
        write_deviations( label = `verify` deviations = writer->verify( spec ) ).
      ENDIF.
    ENDLOOP.

    sync_critical_rule( ).
    report_users( ).
  ENDMETHOD.

  METHOD sync_critical_rule.
    DATA desired      TYPE STANDARD TABLE OF uscrauth WITH EMPTY KEY.
    DATA variants     TYPE STANDARD TABLE OF usrvar WITH EMPTY KEY.
    DATA variant_ids  TYPE STANDARD TABLE OF usrvarid WITH EMPTY KEY.
    DATA comb_vars    TYPE STANDARD TABLE OF usrvarcom WITH EMPTY KEY.
    DATA comb_var_ids TYPE STANDARD TABLE OF usrcrcomb WITH EMPTY KEY.

    out->write( |--- SUIM critical authorization { co_debug_rule }, combination { co_debug_comb }, variants| ).
    desired = VALUE #( ( mandt = sy-mandt auth_id = co_debug_rule objct = 'S_DEVELOP'
                         field = 'OBJTYPE' low = 'DEBUG' searchtype = 'AND' )
                       ( mandt = sy-mandt auth_id = co_debug_rule objct = 'S_DEVELOP'
                         field = 'ACTVT' low = '02' searchtype = 'AND' ) ).

    SELECT * FROM uscrauth WHERE auth_id = @co_debug_rule ORDER BY PRIMARY KEY INTO TABLE @DATA(current).
    SORT desired BY auth_id cr_auth objct field low high.
    SELECT SINGLE auth_color FROM uscrauthid WHERE auth_id = @co_debug_rule INTO @DATA(color).
    DATA(rule_ok) = xsdbool( sy-subrc = 0 AND color = '6' AND current = desired ).
    SELECT COUNT(*) FROM usrvarid WHERE varname = @co_variant AND auth_id = @co_debug_rule INTO @DATA(in_variant).
    SELECT COUNT(*) FROM uscrcomid WHERE comb_id = @co_debug_comb INTO @DATA(comb_parts).
    SELECT COUNT(*) FROM usrcrcomb WHERE varname = @co_comb_variant AND comb_id = @co_debug_comb INTO @DATA(in_comb_variant).
    IF rule_ok = abap_true AND in_variant = 1 AND comb_parts = 2 AND in_comb_variant = 1.
      out->write( `  plan: conforms` ).
      RETURN.
    ENDIF.
    out->write( |  plan: differs (rule { COND #( WHEN rule_ok = abap_true THEN `ok` ELSE `missing` ) }, | &&
                |variant { in_variant }, combination parts { comb_parts }, combination variant { in_comb_variant })| ).
    IF co_apply_rules = abap_false.
      RETURN.
    ENDIF.

    SELECT SINGLE cccategory FROM t000 WHERE mandt = @sy-mandt INTO @DATA(category).
    IF category = 'P'.
      out->write( `  refused: production client` ).
      RETURN.
    ENDIF.

    " critical authorization
    MODIFY uscrauthid FROM @( VALUE #( mandt = sy-mandt auth_id = co_debug_rule auth_color = '6' ) ).
    MODIFY uscrauidt FROM TABLE @( VALUE #(
      ( mandt = sy-mandt langu = 'E' auth_id = co_debug_rule text = 'ACCX test: debugging with replace' )
      ( mandt = sy-mandt langu = 'D' auth_id = co_debug_rule text = 'ACCX Test: Debuggen mit Ändern' ) ) ).
    DELETE FROM uscrauth WHERE auth_id = @co_debug_rule.
    INSERT uscrauth FROM TABLE @desired.

    " variant of critical authorizations (key-only tables: insert, duplicates are fine)
    variants    = VALUE #( ( mandt = sy-mandt varname = co_variant ) ).
    variant_ids = VALUE #( ( mandt = sy-mandt varname = co_variant auth_id = co_debug_rule ) ).
    INSERT usrvar FROM TABLE @variants ACCEPTING DUPLICATE KEYS.
    INSERT usrvarid FROM TABLE @variant_ids ACCEPTING DUPLICATE KEYS.
    MODIFY usrvart FROM TABLE @( VALUE #(
      ( mandt = sy-mandt langu = 'E' varname = co_variant vtext = 'ACCX test: critical authorizations' )
      ( mandt = sy-mandt langu = 'D' varname = co_variant vtext = 'ACCX Test: kritische Berechtigungen' ) ) ).

    " critical combination: debugging with replace AND table maintenance (SAP sample SAP_CTBA)
    MODIFY usrcomb FROM @( VALUE #( mandt = sy-mandt comb_id = co_debug_comb comb_col = '6' ) ).
    MODIFY usrcombt FROM TABLE @( VALUE #(
      ( mandt = sy-mandt langu = 'E' comb_id = co_debug_comb ctext = 'ACCX test: debugging with replace + table maint.' )
      ( mandt = sy-mandt langu = 'D' comb_id = co_debug_comb ctext = 'ACCX Test: Debuggen mit Ändern + Tabellenpflege' ) ) ).
    DELETE FROM uscrcomid WHERE comb_id = @co_debug_comb.
    INSERT uscrcomid FROM TABLE @( VALUE #(
      ( mandt = sy-mandt comb_id = co_debug_comb auth_id = co_debug_rule searchtype = 'AND' )
      ( mandt = sy-mandt comb_id = co_debug_comb auth_id = 'SAP_CTBA' searchtype = 'AND' ) ) ).
    comb_vars    = VALUE #( ( mandt = sy-mandt varname = co_comb_variant ) ).
    comb_var_ids = VALUE #( ( mandt = sy-mandt varname = co_comb_variant comb_id = co_debug_comb ) ).
    INSERT usrvarcom FROM TABLE @comb_vars ACCEPTING DUPLICATE KEYS.
    INSERT usrcrcomb FROM TABLE @comb_var_ids ACCEPTING DUPLICATE KEYS.
    MODIFY usrvarcomt FROM TABLE @( VALUE #(
      ( mandt = sy-mandt langu = 'E' varname = co_comb_variant vtext = 'ACCX test: critical combinations' )
      ( mandt = sy-mandt langu = 'D' varname = co_comb_variant vtext = 'ACCX Test: kritische Kombinationen' ) ) ).

    COMMIT WORK AND WAIT.
    out->write( `  applied` ).
  ENDMETHOD.

  METHOD write_deviations.
    IF deviations IS INITIAL.
      out->write( |  { label }: conforms| ).
      RETURN.
    ENDIF.
    LOOP AT deviations INTO DATA(deviation).
      out->write( |  { label }: { deviation-kind } { deviation-detail }| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD report_users.
    out->write( `--- users ACCX*` ).
    SELECT bname, class, uflag, ustyp FROM usr02 WHERE bname LIKE 'ACCX%' ORDER BY bname INTO TABLE @DATA(users).
    LOOP AT users INTO DATA(user).
      SELECT agr_name, from_dat, to_dat FROM agr_users WHERE uname = @user-bname INTO TABLE @DATA(assignments).
      out->write( |{ user-bname } type={ user-ustyp } group={ user-class } lock={ user-uflag } roles=[| &&
                  |{ concat_lines_of( table = VALUE string_table( FOR a IN assignments ( |{ a-agr_name }({ a-from_dat }-{ a-to_dat })| ) ) sep = `, ` ) }]| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD desired_roles.
    result = VALUE #(
      ( name    = 'ZACCX_T_MONITOR'
        text    = 'ACCX test: system monitoring (display)'
        tcodes  = VALUE #( ( 'SM21' ) ( 'SM37' ) ( 'ST22' ) )
        " ST22 proposes S_DEVELOP (debugging); keep monitoring users free of it
        exclude = VALUE #( ( 'S_DEVELOP' ) ) )
      ( name    = 'ZACCX_T_DEVDISP'
        text    = 'ACCX test: development display only'
        tcodes  = VALUE #( ( 'SE80' ) ( 'SE38' ) ( 'SE11' ) )
        exclude = VALUE #( ( 'S_DEVELOP' ) )
        values  = VALUE #( ( object = 'S_DEVELOP' field = 'ACTVT'    low = '03' )
                           ( object = 'S_DEVELOP' field = 'DEVCLASS' low = '*' )
                           ( object = 'S_DEVELOP' field = 'OBJNAME'  low = '*' )
                           ( object = 'S_DEVELOP' field = 'OBJTYPE'  low = '*' )
                           ( object = 'S_DEVELOP' field = 'P_GROUP'  low = '*' ) ) )
      " SE16N does not exist on A4H (ABAP Platform without ERP), SE16 is used instead
      ( name   = 'ZACCX_T_CRITICAL'
        text   = 'ACCX test: critical authorizations'
        tcodes = VALUE #( ( 'SE16' ) ( 'SM59' ) )
        values = VALUE #( ( object = 'S_TABU_DIS' field = 'ACTVT'     low = '02' )
                          ( object = 'S_TABU_DIS' field = 'DICBERCLS' low = '*' )
                          ( object = 'S_DEVELOP'  field = 'ACTVT'     low = '02' )
                          ( object = 'S_DEVELOP'  field = 'OBJTYPE'   low = 'DEBUG' )
                          ( object = 'S_DEVELOP'  field = 'DEVCLASS'  low = '*' )
                          ( object = 'S_DEVELOP'  field = 'OBJNAME'   low = '*' )
                          ( object = 'S_DEVELOP'  field = 'P_GROUP'   low = '*' )
                          ( object = 'S_RFC'      field = 'ACTVT'     low = '16' )
                          ( object = 'S_RFC'      field = 'RFC_TYPE'  low = '*' )
                          ( object = 'S_RFC'      field = 'RFC_NAME'  low = '*' ) ) )
      " S_RFC is not excluded: SU24 proposals (RFC1, SUST, PRGN_*) stay for SUIM/PFCG
      ( name    = 'ZACCX_T_SUPPORT'
        text    = 'ACCX test: support agent (MCP caller)'
        tcodes  = VALUE #( ( 'SU01D' ) ( 'SUIM' ) ( 'SU53' ) ( 'PFCG' ) )
        exclude = VALUE #( ( 'S_USER_GRP' ) ( 'S_USER_AGR' ) ( 'S_USER_PRO' ) ( 'S_USER_AUT' )
                           ( 'S_ADMI_FCD' ) )
        values  = VALUE #( ( object = 'S_USER_GRP' field = 'ACTVT'      low = '03' )
                           ( object = 'S_USER_GRP' field = 'ACTVT'      low = '08' )
                           ( object = 'S_USER_GRP' field = 'CLASS'      low = 'ACCX_TEST' )
                           ( object = 'S_USER_AGR' field = 'ACTVT'      low = '03' )
                           ( object = 'S_USER_AGR' field = 'ACTVT'      low = '08' )
                           ( object = 'S_USER_AGR' field = 'ACT_GROUP'  low = 'ZACCX_T_*' )
                           ( object = 'S_USER_PRO' field = 'ACTVT'      low = '03' )
                           ( object = 'S_USER_PRO' field = 'ACTVT'      low = '08' )
                           ( object = 'S_USER_PRO' field = 'PROFILE'    low = '*' )
                           ( object = 'S_USER_AUT' field = 'ACTVT'      low = '03' )
                           ( object = 'S_USER_AUT' field = 'ACTVT'      low = '08' )
                           ( object = 'S_USER_AUT' field = 'OBJECT'     low = '*' )
                           ( object = 'S_USER_AUT' field = 'AUTH'       low = '*' )
                           ( object = 'S_RFC'      field = 'ACTVT'      low = '16' )
                           ( object = 'S_RFC'      field = 'RFC_TYPE'   low = 'FUGR' )
                           ( object = 'S_RFC'      field = 'RFC_NAME'   low = 'SUSR_SUIM_APIS' )
                           ( object = 'S_RFC'      field = 'RFC_NAME'   low = 'SUSR_USER_SU53' )
                           ( object = 'S_ADMI_FCD' field = 'S_ADMI_FCD' low = 'STUR' ) ) )
      ( name      = 'ZACCX_T_C_COMBO'
        text      = 'ACCX test: composite monitor + dev display'
        composite = abap_true
        children  = VALUE #( ( 'ZACCX_T_MONITOR' ) ( 'ZACCX_T_DEVDISP' ) ) ) ).
  ENDMETHOD.

ENDCLASS.
