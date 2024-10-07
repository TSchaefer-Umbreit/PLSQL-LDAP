  g_ldap_host     varchar2(50);
  g_ldap_port     number;
  g_ldap_bind_dn  varchar2(200);
  g_ldap_passwd   varchar2(200);
  g_ldap_user_dn  varchar2(200);


/**
  * Bind to LDAP Server and return the LDAP session
  *
  * @sice 13.6.2023
  * @author TS
  */
  function ldap_bind return dbms_ldap.session is
    l_session        dbms_ldap.session;
    l_status         pls_integer;
  begin
    -- Globale Variablen laden
    if g_ldap_host is null then
      load_globals;
    end if;

    dbms_output.put_line('Bind to ' || g_ldap_host || ' on Port ' || g_ldap_port);
    -- Bind LDAP Session
    l_session := dbms_ldap.init(g_ldap_host, g_ldap_port);
    l_status := dbms_ldap.simple_bind_s(l_session, g_ldap_bind_dn, g_ldap_passwd);

    -- If bind was successfull, return the Session
    if l_status = dbms_ldap.success then
      return l_session;
    else
      dbms_output.put_line('Fehler beim herstellen der LDAP Verbindung');
      return null;
    end if;
  end;

  /**
  * Unbind LDAP Server
  *
  * @sice 27.6.2023
  * @author TS
  * @param  in_session
  */
  procedure ldap_unbind(in_session dbms_ldap.session) is
    l_session        dbms_ldap.session;
    l_status         pls_integer;
  begin
    l_session := in_session;
    l_status := dbms_ldap.unbind_s(l_session);
    if l_status != dbms_ldap.success then
      set_error('Fehler beim beenden der LDAP Verbindung');
    end if;
  end;


  /**
  * Fragt ein beliebiges Attribut zu einer CN (Benutzer) ab
  *
  * @sice 12.9.2023
  * @author TS
  * @param    varchar2   in_attr
  * @param    varchar2   in_cn
  * @return   varchar2
  */
  function ldap_get_value(in_attr varchar2, in_cn varchar2) return varchar2 is
    l_session       dbms_ldap.session;
    l_attrs         dbms_ldap.string_collection;
    l_entry         dbms_ldap.message;
    l_message       dbms_ldap.message;
    l_result        dbms_ldap.string_collection;
    l_return        varchar2(32767);
  begin
    l_session  := ldap_bind;
    l_attrs(1) := in_attr;
    g_ret      := dbms_ldap.search_s(
      ld          => l_session,
      base        => g_ldap_user_dn,
      scope       => dbms_ldap.scope_subtree,
      filter      => '(cn=' || in_cn || ')',
      attrs       => l_attrs,
      attronly    => 0,
      res         => l_message
    );

    if dbms_ldap.count_entries(l_session, l_message) > 0 then
      l_entry := dbms_ldap.first_entry(l_session, l_message);
      l_result := dbms_ldap.get_values(l_session, l_entry, in_attr);
      l_return := l_result(0);
      ldap_unbind(l_session);
      return l_return;
    else
      ldap_unbind(l_session);
      return null;
    end if;
  exception
    when others then
      dbms_output.put_line(sqlerrm || chr(10) || dbms_utility.format_error_backtrace);
      return null;
  end;
