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


  method CREATE_TRANSPORT.
    IF is_checks-transport-required = abap_true AND is_checks-transport-transport IS INITIAL.
      data lv_text type AS4TEXT.
      data lv_name type string.
      data lv_package type DEVCLASS.
      data ls_req type TRWBO_REQUEST_HEADER.
      data lt_task type TRWBO_REQUEST_HEADERS.
      data lt_user type SCTS_USERS.
      data ls_user like line of lt_user.

      lv_name = io_repo->MS_DATA-local_settings-DISPLAY_NAME.
      lv_package = io_repo->GET_PACKAGE( ).
      concatenate lv_name ' (' io_repo->MS_DATA-BRANCH_NAME ')' into lv_text.

      ls_user-user = sy-uname.
*      ls_user-type = 'S'.  " Development, not a repair
      append ls_user to lt_user.

      CALL FUNCTION 'TR_INSERT_REQUEST_WITH_TASKS'
        EXPORTING
          IV_TYPE                  = 'K'
          IV_TEXT                  = lv_text
         IV_OWNER                 = SY-UNAME
*         IV_TARGET                =
*         IT_ATTRIBUTES            =
         IT_USERS                 = lt_user
*         IV_TARDEVCL              =
         IV_DEVCLASS              = lv_package
*         IV_TARLAYER              =
*         IV_WITH_BADI_CHECK       =
       IMPORTING
         ES_REQUEST_HEADER        = ls_req
         ET_TASK_HEADERS          = lt_task
       EXCEPTIONS
         INSERT_FAILED            = 1
         ENQUEUE_FAILED           = 2
         OTHERS                   = 3
                .
      IF SY-SUBRC <> 0.
        RAISE EXCEPTION TYPE ZCX_ABAPGIT_EXCEPTION
           EXPORTING
            MSGV1  = sy-msgv1
            MSGV2  = sy-msgv2
            MSGV3  = sy-msgv3
            MSGV4  = sy-msgv4
            .

* Implement suitable error handling here
      else.
        is_checks-transport-transport = ls_req-trkorr.
      ENDIF.
    ENDIF.
  endmethod.


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
