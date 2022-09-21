CLASS zcl_abapgit_background_pull DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES zif_abapgit_background .
  PROTECTED SECTION.
private section.

  methods CREATE_TRANSPORT
    importing
      !IO_REPO type ref to ZCL_ABAPGIT_REPO_ONLINE
    changing
      !IS_CHECKS type ZIF_ABAPGIT_DEFINITIONS=>TY_DESERIALIZE_CHECKS
    raising
      ZCX_ABAPGIT_EXCEPTION .
ENDCLASS.



CLASS ZCL_ABAPGIT_BACKGROUND_PULL IMPLEMENTATION.


  METHOD create_transport.
    IF is_checks-transport-required = abap_true AND is_checks-transport-transport IS INITIAL.
"      SELECT SINGLE * FROM e070use INTO @DATA(wa_e070use)
"        WHERE username = @sy-uname
"          AND trfunction = 'K'.
"      IF sy-subrc = 0.
"        is_checks-transport-transport = wa_e070use-ordernum.
"      ELSE.
        " no default transport selected yet, create one
      DATA lv_text TYPE as4text.
      DATA lv_name TYPE string.
      DATA lv_package TYPE devclass.
      DATA ls_req TYPE trwbo_request_header.
      DATA lt_task TYPE trwbo_request_headers.
      DATA lt_user TYPE scts_users.
      DATA ls_user LIKE LINE OF lt_user.

      lv_name = io_repo->ms_data-local_settings-display_name.
      lv_package = io_repo->get_package( ).
      CONCATENATE lv_name ' (' io_repo->ms_data-branch_name ')' INTO lv_text.

      ls_user-user = sy-uname.
*      ls_user-type = 'S'.  " Development, not a repair
      APPEND ls_user TO lt_user.

      CALL FUNCTION 'TR_INSERT_REQUEST_WITH_TASKS'
        EXPORTING
          iv_type                  = 'K'
          iv_text                  = lv_text
         iv_owner                 = sy-uname
*         IV_TARGET                =
*         IT_ATTRIBUTES            =
         it_users                 = lt_user
*         IV_TARDEVCL              =
         iv_devclass              = lv_package
*         IV_TARLAYER              =
*         IV_WITH_BADI_CHECK       =
       IMPORTING
         es_request_header        = ls_req
         et_task_headers          = lt_task
       EXCEPTIONS
         insert_failed            = 1
         enqueue_failed           = 2
         OTHERS                   = 3
                .
      IF sy-subrc = 0.
            is_checks-transport-transport = ls_req-trkorr.
         ELSE.
        RAISE EXCEPTION TYPE zcx_abapgit_exception
           EXPORTING
            msgv1  = sy-msgv1
            msgv2  = sy-msgv2
            msgv3  = sy-msgv3
            msgv4  = sy-msgv4
            .

      ENDIF.
"        ENDIF.
    ENDIF.
  ENDMETHOD.


  METHOD zif_abapgit_background~get_description.

    rv_description = 'Automatic pull'.

  ENDMETHOD.


  METHOD zif_abapgit_background~get_settings.
    RETURN.
  ENDMETHOD.


  METHOD zif_abapgit_background~run.

    DATA: ls_checks TYPE zif_abapgit_definitions=>ty_deserialize_checks.

    FIELD-SYMBOLS: <ls_overwrite> LIKE LINE OF ls_checks-overwrite.


    ls_checks = io_repo->deserialize_checks( ).

    LOOP AT ls_checks-overwrite ASSIGNING <ls_overwrite>.
      <ls_overwrite>-decision = zif_abapgit_definitions=>c_yes.
    ENDLOOP.

    CALL METHOD create_transport
      EXPORTING
        io_repo   = io_repo
      changing
        is_checks = ls_checks    .

    io_repo->deserialize( is_checks = ls_checks
                          ii_log    = ii_log ).

  ENDMETHOD.
ENDCLASS.
