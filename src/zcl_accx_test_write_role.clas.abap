"! <p class="shorttext synchronized">Access Explorer: reset test role ZACCX_T_WRITE (F9)</p>
"! ZACCX_T_WRITE is the target of the live tests of apply_role_change, the
"! composite role ZACCX_T_C_WRITE (containing ZACCX_T_WRITE) the target of its
"! composite role tests, ZACCX_T_D_WRITE (derived from ZACCX_T_WRITE) receives
"! the changes of ZACCX_T_WRITE. F9 deletes the three roles and creates them
"! again - ZACCX_T_WRITE with menu SM37 only (authorizations from SU24, empty
"! fields filled with *), the derived role with the authorizations passed on -
"! then lists menu, catalogs, open fields, single roles and derived values.
"! ZACCX_T_NEW and ZACCX_T_COPY, the roles the live tests of apply_role_change
"! create (create = true), are deleted and not created again.
"! Never in production clients; the roles have no users.
CLASS zcl_accx_test_write_role DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

    CONSTANTS co_role      TYPE agr_name VALUE 'ZACCX_T_WRITE'.
    CONSTANTS co_composite TYPE agr_name VALUE 'ZACCX_T_C_WRITE'.
    CONSTANTS co_derived   TYPE agr_name VALUE 'ZACCX_T_D_WRITE'.
    CONSTANTS co_new       TYPE agr_name VALUE 'ZACCX_T_NEW'.
    CONSTANTS co_copy      TYPE agr_name VALUE 'ZACCX_T_COPY'.

ENDCLASS.

CLASS zcl_accx_test_write_role IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
    DATA messages   TYPE STANDARD TABLE OF sprot_u.
    DATA error_flag TYPE char01.
    DATA return     TYPE STANDARD TABLE OF bapiret2.
    DATA transfer   TYPE bapirettab.
    DATA request    TYPE trkorr.

    SELECT SINGLE cccategory FROM t000 WHERE mandt = @sy-mandt INTO @DATA(category).
    IF category = 'P'.
      out->write( `Refused: production client.` ).
      RETURN.
    ENDIF.
    DATA(roles) = VALUE zif_accx_role_writer=>ty_names( ( co_new ) ( co_copy ) ( co_composite ) ( co_derived ) ( co_role ) ).
    LOOP AT roles INTO DATA(role).
      SELECT COUNT(*) FROM agr_users WHERE agr_name = @role INTO @DATA(users).
      IF users > 0.
        out->write( |Refused: { role } is assigned to { users } users.| ).
        RETURN.
      ENDIF.
    ENDLOOP.

    " composite and derived role first, so that the single role is no longer used anywhere
    LOOP AT roles INTO role.
      SELECT SINGLE @abap_true FROM agr_define WHERE agr_name = @role INTO @DATA(exists).
      IF exists = abap_true.
        CALL FUNCTION 'PRGN_ACTIVITY_GROUP_DELETE'
          EXPORTING
            activity_group        = role
            enqueue_and_transport = ' '
            show_dialog           = ' '
          IMPORTING
            error_flag            = error_flag
          TABLES
            messages              = messages
          EXCEPTIONS
            OTHERS                = 1.
        out->write( |delete { role }: subrc { sy-subrc } error flag "{ error_flag }"| ).
        COMMIT WORK AND WAIT.
      ENDIF.
      CLEAR exists.
    ENDLOOP.

    DATA(writer) = CAST zif_accx_role_writer( NEW zcl_accx_role_writer( ) ).
    DATA(steps) = writer->apply( VALUE #( name = co_role text = 'ACCX test: target of apply_role_change' tcodes = VALUE #( ( 'SM37' ) ) ) ).
    COMMIT WORK AND WAIT.
    APPEND LINES OF writer->apply( VALUE #( name      = co_composite
                                            text      = 'ACCX test: composite target of apply_role_change'
                                            composite = abap_true
                                            children  = VALUE #( ( co_role ) ) ) ) TO steps.
    COMMIT WORK AND WAIT.
    CALL FUNCTION 'PRGN_RFC_CREATE_AGR_MULTIPLE'
      EXPORTING
        activity_group      = co_derived
        parent_role         = co_role
        activity_group_text = 'ACCX test: derived from ZACCX_T_WRITE'
        no_dialog           = 'X'
      TABLES
        return              = return
      EXCEPTIONS
        OTHERS              = 1.
    APPEND VALUE #( role = co_derived step = `create derived role` ok = xsdbool( sy-subrc = 0 )
                    messages = VALUE #( FOR r IN return WHERE ( type CA 'EA' ) ( CONV #( r-message ) ) ) ) TO steps.
    COMMIT WORK AND WAIT.
    " the hierarchy buffer of PFCG (read while deleting) does not know the new derived role yet;
    " PFCG itself adds new derived roles this way
    SELECT SINGLE * FROM agr_define WHERE agr_name = @co_derived INTO @DATA(definition).
    PERFORM update_agr_table IN PROGRAM saplprgn_tree USING definition IF FOUND.
    CALL FUNCTION 'SUPRN_TRANSFER_AUTH_DATA'
      EXPORTING
        top_activity_group = co_role
        generate_profiles  = 'X'
        no_dialog          = 'X'
      IMPORTING
        return             = transfer
      CHANGING
        request            = request.
    APPEND VALUE #( role = co_derived step = `pass on authorizations` ok = xsdbool( NOT line_exists( transfer[ type = 'E' ] ) )
                    messages = VALUE #( FOR m IN transfer ( |{ m-type } { m-id }/{ m-number } { m-message }| ) ) ) TO steps.
    COMMIT WORK AND WAIT.
    LOOP AT steps INTO DATA(step).
      out->write( |{ COND #( WHEN step-ok = abap_true THEN `ok    ` ELSE `FAILED` ) } { step-role } { step-step } | &&
                  |{ concat_lines_of( table = step-messages sep = ` | ` ) }| ).
    ENDLOOP.

    SELECT tcode FROM agr_tcodes WHERE agr_name = @co_role AND type = 'TR' INTO TABLE @DATA(tcodes).
    SELECT COUNT(*) FROM agr_buffi WHERE agr_name = @co_role AND url LIKE 'X-SAP-UI2-CATALOGPAGE:%' INTO @DATA(catalogs).
    DATA(open) = NEW zcl_accx_role_changer( )->zif_accx_role_changer~get_open_fields( co_role ).
    SELECT SINGLE generated FROM agr_1016 WHERE agr_name = @co_role INTO @DATA(generated).
    out->write( |{ co_role }: menu { concat_lines_of( table = VALUE string_table( FOR t IN tcodes ( CONV #( t-tcode ) ) ) sep = `, ` ) }, | &&
                |catalogs { catalogs }, open fields { lines( open ) }, generated { generated }| ).
    SELECT child_agr FROM agr_agrs WHERE agr_name = @co_composite INTO TABLE @DATA(children).
    out->write( |{ co_composite }: single roles { concat_lines_of( table = VALUE string_table( FOR c IN children ( CONV #( c-child_agr ) ) )
                                                                    sep   = `, ` ) }| ).
    SELECT COUNT(*) FROM agr_1251 WHERE agr_name = @co_derived AND deleted = @space INTO @DATA(derived_values).
    SELECT SINGLE generated FROM agr_1016 WHERE agr_name = @co_derived INTO @DATA(derived_generated).
    out->write( |{ co_derived }: derived from { co_role }, { derived_values } authorization values, generated { derived_generated }| ).
  ENDMETHOD.

ENDCLASS.

