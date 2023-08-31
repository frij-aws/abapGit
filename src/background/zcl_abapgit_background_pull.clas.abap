CLASS zcl_abapgit_background_pull DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES zif_abapgit_background .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_ABAPGIT_BACKGROUND_PULL IMPLEMENTATION.


  METHOD zif_abapgit_background~get_description.

    rv_description = 'Automatic pull'.

  ENDMETHOD.


  METHOD zif_abapgit_background~get_settings.
    RETURN.
  ENDMETHOD.


  METHOD zif_abapgit_background~run.

    DATA: ls_checks TYPE zif_abapgit_definitions=>ty_deserialize_checks.
    data: lo_exit type ref to zif_abapgit_exit.

    FIELD-SYMBOLS: <ls_overwrite> LIKE LINE OF ls_checks-overwrite.


    ls_checks = io_repo->deserialize_checks( ).

    LOOP AT ls_checks-overwrite ASSIGNING <ls_overwrite>.
      <ls_overwrite>-decision = zif_abapgit_definitions=>c_yes.
    ENDLOOP.

    lo_exit = ZCL_ABAPGIT_EXIT=>GET_INSTANCE( ).
    lo_exit->change_checks( CHANGING cs_checks = ls_checks ).

    io_repo->deserialize( is_checks = ls_checks
                          ii_log    = ii_log ).

  ENDMETHOD.
ENDCLASS.
