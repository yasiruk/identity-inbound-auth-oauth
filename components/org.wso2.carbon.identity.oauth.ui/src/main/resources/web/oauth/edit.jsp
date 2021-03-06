<!--
 ~ Copyright (c) 2013, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 ~
 ~ WSO2 Inc. licenses this file to you under the Apache License,
 ~ Version 2.0 (the "License"); you may not use this file except
 ~ in compliance with the License.
 ~ You may obtain a copy of the License at
 ~
 ~    http://www.apache.org/licenses/LICENSE-2.0
 ~
 ~ Unless required by applicable law or agreed to in writing,
 ~ software distributed under the License is distributed on an
 ~ "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 ~ KIND, either express or implied.  See the License for the
 ~ specific language governing permissions and limitations
 ~ under the License.
 -->
<%@ page import="org.apache.axis2.context.ConfigurationContext"%>
<%@ page import="org.owasp.encoder.Encode" %>
<%@ page import="org.wso2.carbon.CarbonConstants" %>
<%@ page import="org.wso2.carbon.identity.oauth.common.OAuthConstants" %>
<%@ page import="org.wso2.carbon.identity.oauth.stub.dto.OAuthConsumerAppDTO" %>
<%@ page import="org.wso2.carbon.identity.oauth.ui.client.OAuthAdminClient" %>
<%@ page import="org.wso2.carbon.identity.oauth.ui.util.OAuthUIUtil" %>
<%@ page import="org.wso2.carbon.ui.CarbonUIMessage" %>
<%@ page import="org.wso2.carbon.ui.CarbonUIUtil"%>
<%@ page import="org.wso2.carbon.utils.ServerConstants" %>

<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.Arrays" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.ResourceBundle" %>

<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib uri="http://wso2.org/projects/carbon/taglibs/carbontags.jar" prefix="carbon" %>

<script type="text/javascript" src="extensions/js/vui.js"></script>
<script type="text/javascript" src="../extensions/core/js/vui.js"></script>
<script type="text/javascript" src="../admin/js/main.js"></script>
<script type="text/javascript" src="../identity/validation/js/identity-validate.js"></script>

<jsp:include page="../dialog/display_messages.jsp"/>

<%

    String consumerkey = request.getParameter("consumerkey");
    String appName = request.getParameter("appName");

    OAuthConsumerAppDTO app = null;
    String forwardTo = null;
	String BUNDLE = "org.wso2.carbon.identity.oauth.ui.i18n.Resources";
	ResourceBundle resourceBundle = ResourceBundle.getBundle(BUNDLE, request.getLocale());
	String id = null;
	String secret = null;
	// grants
	boolean codeGrant = false;
    boolean implicitGrant = false;
	boolean passowrdGrant = false;
	boolean clientCredGrant = false;
	boolean refreshGrant = false;
	boolean samlGrant1 = false;
	boolean samlGrant2 = false;
	boolean ntlmGrant = false;
    List<String> allowedGrants = null;
    String applicationSPName = null;
    try {

    	applicationSPName = request.getParameter("appName");
    	session.setAttribute("application-sp-name", applicationSPName);

       	String cookie = (String) session.getAttribute(ServerConstants.ADMIN_SERVICE_COOKIE);
		String backendServerURL = CarbonUIUtil.getServerURL(config.getServletContext(), session);
		ConfigurationContext configContext =
		                                     (ConfigurationContext) config.getServletContext()
		                                                                  .getAttribute(CarbonConstants.CONFIGURATION_CONTEXT);
		OAuthAdminClient client = new OAuthAdminClient(cookie, backendServerURL, configContext);

		if (appName!=null){
			app = client.getOAuthApplicationDataByAppName(appName);
		}else{
			app = client.getOAuthApplicationData(consumerkey);
		}

        if(app.getCallbackUrl() == null){
            app.setCallbackUrl("");
        }
        allowedGrants = new ArrayList<String>(Arrays.asList(client.getAllowedOAuthGrantTypes()));
		if (OAuthConstants.OAuthVersions.VERSION_2.equals(app.getOAuthVersion())) {
			id = resourceBundle.getString("consumerkey.oauth20");
			secret = resourceBundle.getString("consumersecret.oauth20");
		} else {
			id = resourceBundle.getString("consumerkey.oauth10a");
			secret = resourceBundle.getString("consumersecret.oauth10a");
		}
		// setting grants if oauth version 2.0
		if(OAuthConstants.OAuthVersions.VERSION_2.equals(app.getOAuthVersion())){
            String grants = app.getGrantTypes();
            if(grants != null) {
	            codeGrant = grants.contains("authorization_code") ? true : false;
	            implicitGrant = grants.contains("implicit") ? true : false;
	            passowrdGrant = grants.contains("password") ? true : false;
	            clientCredGrant = grants.contains("client_credentials") ? true : false;
	            refreshGrant = grants.contains("refresh_token") ? true : false;
	            samlGrant1 = grants.contains("urn:ietf:params:oauth:grant-type:saml1-bearer") ? true : false;
	            samlGrant2 = grants.contains("urn:ietf:params:oauth:grant-type:saml2-bearer") ? true : false;
	            ntlmGrant = grants.contains("iwa:ntlm") ? true : false;
            }
        }
	} catch (Exception e) {
		String message = resourceBundle.getString("error.while.loading.user.application.data");
		CarbonUIMessage.sendCarbonUIMessage(message, CarbonUIMessage.ERROR, request);
		forwardTo = "../admin/error.jsp";
%>

<script type="text/javascript">
    function forward() {
        location.href = "<%=forwardTo%>";
    }
</script>

<script type="text/javascript">
    forward();
</script>
<%
    }
%>

<fmt:bundle basename="org.wso2.carbon.identity.oauth.ui.i18n.Resources">
    <carbon:breadcrumb label="app.settings"
                       resourceBundle="org.wso2.carbon.identity.oauth.ui.i18n.Resources"
                       topPage="false" request="<%=request%>"/>

    <script type="text/javascript" src="../carbon/admin/js/breadcrumbs.js"></script>
    <script type="text/javascript" src="../carbon/admin/js/cookies.js"></script>
    <script type="text/javascript" src="../carbon/admin/js/main.js"></script>

    <div id="middle">

        <h2><fmt:message key='view.application'/></h2>

        <div id="workArea">
   			<script type="text/javascript">
                function onClickUpdate() {
                    var versionValue = document.getElementsByName("oauthVersion")[0].value;
                    var callbackUrl = document.getElementsByName("callback")[0].value;
                    if (!(versionValue == '<%=OAuthConstants.OAuthVersions.VERSION_2%>')) {
                        if (callbackUrl.trim() == '') {
                            CARBON.showWarningDialog('<fmt:message key="callback.is.required"/>');
                            return false;
                        }else{
                            var isValidated = doValidateInputToConfirm(document.getElementById('callback'), "<fmt:message key='callback.is.not.https'/>",
                                    validate, null, null);
                            if (isValidated) {
                                validate();
                            }
                        }
                    }
                    if($(jQuery("#grant_code"))[0].checked || $(jQuery("#grant_implicit"))[0].checked) {
                         callbackUrl = document.getElementById('callback').value;
                        if (callbackUrl.trim() == '') {
                            CARBON.showWarningDialog('<fmt:message key="callback.is.required"/>');
                            return false;
                        } else {
                            var isValidated = doValidateInputToConfirm(document.getElementById('callback'), "<fmt:message key='callback.is.not.https'/>",
                                    validate, null, null);
                            if (isValidated) {
                                validate();
                            }
                        }
                    } else {
                        validate();
                    }
                }
                function validate() {
                    var callbackUrl = document.getElementById('callback').value;
                    var value = document.getElementsByName("application")[0].value;
                    if (value == '') {
                        CARBON.showWarningDialog('<fmt:message key="application.is.required"/>');
                        return false;
                    }
                    var versionValue = document.getElementsByName("oauthVersion")[0].value;
                    if (versionValue == '<%=OAuthConstants.OAuthVersions.VERSION_2%>') {
                        if (!$(jQuery("#grant_code"))[0].checked && !$(jQuery("#grant_implicit"))[0].checked) {
                            document.getElementsByName("callback")[0].value = '';
                        } else {
                            if (!isWhiteListed(callbackUrl, "url")) {
                                CARBON.showWarningDialog('<fmt:message key="callback.is.not.url"/>');
                                return false;
                            }
                        }
                    } else {
                        if (!isWhiteListed(callbackUrl, "url")) {
                            CARBON.showWarningDialog('<fmt:message key="callback.is.not.url"/>');
                            return false;
                        }
                    }
                    document.editAppform.submit();
                }

                function adjustForm() {
                    var oauthVersion = $('input[name=oauthVersion]:checked').val();
                    var supportGrantCode = $('input[name=grant_code]:checked').val() != null;
                    var supportImplicit = $('input[name=grant_implicit]:checked').val() != null;

                    if(!supportGrantCode && !supportImplicit){
                        $(jQuery('#callback_row')).hide();
                    } else {
                        $(jQuery('#callback_row')).show();
                    }
                    if(supportGrantCode) {
                        $(jQuery("#pkce_enable").show());
                        $(jQuery("#pkce_support_plain").show());
                    } else {
                        $(jQuery("#pkce_enable").hide());
                        $(jQuery("#pkce_support_plain").hide());
                    }

                }
                jQuery(document).ready(function() {
                    //on load adjust the form based on the current settings
                    adjustForm();
                    $("form[name='editAppform']").change(adjustForm);
                })
            </script>

            <form method="post" name="editAppform"  action="edit-finish.jsp"  target="_self">
            	<input id="consumerkey" name="consumerkey" type="hidden" value="<%=Encode.forHtmlAttribute(app.getOauthConsumerKey())%>" />
		        <input id="consumersecret" name="consumersecret" type="hidden" value="<%=Encode.forHtmlAttribute(app.getOauthConsumerSecret())%>" />
                <table style="width: 100%" class="styledLeft">
                    <thead>
                    <tr>
                        <th><fmt:message key='app.settings'/></th>
                    </tr>
                    </thead>
                    <tbody>
                    <tr>
			<td class="formRow">
				<table class="normal" cellspacing="0">
                            <tr>
                                <td class="leftCol-small"><fmt:message key='oauth.version'/></td>
                                <td><%=Encode.forHtml(app.getOAuthVersion())%><input id="oauthVersion" name="oauthVersion"
                                                                        type="hidden" value="<%=Encode.forHtmlAttribute(app.getOAuthVersion())%>" /></td>
                            </tr>
                            <%if (applicationSPName ==null) { %>
				           <tr>
		                        <td class="leftCol-small"><fmt:message key='application.name'/><span class="required">*</span></td>
		                        <td><input class="text-box-big" id="application" name="application"
		                                   type="text" value="<%=Encode.forHtmlAttribute(app.getApplicationName())%>" /></td>
		                    </tr>
		                    <%}else { %>
		                    <tr style="display: none;">
		                        <td colspan="2" style="display: none;"><input class="text-box-big" id="application" name="application"
		                                   type="hidden" value="<%=Encode.forHtmlAttribute(applicationSPName)%>" /></td>
		                    </tr>
		                    <%} %>
		                    <tr id="callback_row">
		                        <td class="leftCol-small"><fmt:message key='callback'/><span class="required">*</span></td>
                                <td><input class="text-box-big" id="callback" name="callback"
                                           type="text" value="<%=Encode.forHtmlAttribute(app.getCallbackUrl())%>"
                                           white-list-patterns="https-url"/></td>
		                    </tr>
                            <script>
                                if(<%=app.getOAuthVersion().equals(OAuthConstants.OAuthVersions.VERSION_1A)%> || <%=codeGrant%> || <%=implicitGrant%>){
                                    $(jQuery('#callback_row')).attr('style','');
                                } else {
                                    $(jQuery('#callback_row')).attr('style','display:none');
                                }
                            </script>
                            <% if(app.getOAuthVersion().equals(OAuthConstants.OAuthVersions.VERSION_2)){ %>
                                 <tr id="grant_row" name="grant_row">
                                    <td class="leftCol-small"><fmt:message key='grantTypes'/></td>
                                    <td>
                                    <table>
                                    <%
                                        try{
                                            if(allowedGrants.contains("authorization_code")){
                                                %><tr><label><input type="checkbox" id="grant_code" name="grant_code" value="authorization_code"  <%=(codeGrant ? "checked=\"checked\"" : "")%>/>Code</label></tr><%
                                            }
                                            if(allowedGrants.contains("implicit")){
                                                %><tr><label><input type="checkbox" id="grant_implicit" name="grant_implicit" value="implicit"  <%=(implicitGrant ? "checked=\"checked\"" : "")%>/>Implicit</label></tr><%
                                            }
                                            if(allowedGrants.contains("password")){
                                                %><tr><lable><input type="checkbox" id="grant_password" name="grant_password" value="password"  <%=(passowrdGrant ? "checked=\"checked\"" : "")%>/>Password</lable></tr><%
                                            }
                                            if(allowedGrants.contains("client_credentials")){
                                                %><tr><label><input type="checkbox" id="grant_client" name="grant_client" value="client_credentials"  <%=(clientCredGrant ? "checked=\"checked\"" : "")%>/>Client Credential</label></tr><%
                                            }
                                            if(allowedGrants.contains("refresh_token")){
                                                %><tr><label><input type="checkbox" id="grant_refresh" name="grant_refresh" value="refresh_token"  <%=(refreshGrant ? "checked=\"checked\"" : "")%>/>Refresh Token</label></tr><%
                                            }
                                            if(allowedGrants.contains("urn:ietf:params:oauth:grant-type:saml1-bearer")){
                                                %><tr><tr><label><input type="checkbox" id="grant_saml1" name="grant_saml1" value="urn:ietf:params:oauth:grant-type:saml1-bearer"  <%=(samlGrant1 ? "checked=\"checked\"" : "")%>/>SAML1</label></tr><%
                                            }
                                            if(allowedGrants.contains("urn:ietf:params:oauth:grant-type:saml2-bearer")){
                                                %><tr><tr><label><input type="checkbox" id="grant_saml2" name="grant_saml2" value="urn:ietf:params:oauth:grant-type:saml2-bearer"  <%=(samlGrant2 ? "checked=\"checked\"" : "")%>/>SAML2</label></tr><%
                                            } if(allowedGrants.contains("iwa:ntlm")){
                                                %><tr><tr><label><input type="checkbox" id="grant_ntlm" name="grant_ntlm" value="iwa:ntlm"  <%=(ntlmGrant ? "checked=\"checked\"" : "")%>/>IWA-NTLM</label></tr><%
                                            }
                                    } catch (Exception e){
                                        forwardTo = "../admin/error.jsp";
                                        String message = resourceBundle.getString("error.while.getting.allowed.grants") + " : " + e.getMessage();
                                        CarbonUIMessage.sendCarbonUIMessage(message, CarbonUIMessage.ERROR, request, e);
                                    %>

                                        <script type="text/javascript">
                                            function forward() {
                                                location.href = "<%=forwardTo%>";
                                            }
                                        </script>

                                        <script type="text/javascript">
                                            forward();
                                        </script>
                                    <%
                                    }
                                    %>
                                    </table>
                                    </td>
                                </tr>
                                <tr id="pkce_enable">
                                    <td class="leftcol-small">
                                        <fmt:message key='pkce.mandatory'/>
                                    </td>
                                    <td>
                                        <input type="checkbox" name="pkce" value="mandatory" <%=(app.getPkceMandatory() ? "checked" : "")%>  />Mandatory
                                        <div class="sectionHelp">
                                            <fmt:message key='pkce.mandatory.hint'/>
                                        </div>
                                    </td>
                                </tr>
                                <tr id="pkce_support_plain">
                                    <td>
                                        <fmt:message key='pkce.support.plain'/>
                                    </td>
                                    <td>
                                        <input type="checkbox" name="pkce_plain" value="yes" <%=(app.getPkceSupportPlain() ? "checked" : "")%>>Yes
                                        <div class="sectionHelp">
                                            <fmt:message key='pkce.support.plain.hint'/>
                                        </div>
                                    </td>
                                </tr>
                            <% } %>
				</table>
			</td>
		    </tr>
                    <tr>
                        <td class="buttonRow">
                           <input name="update"
                                   type="button" class="button" value="<fmt:message key='update'/>" onclick="onClickUpdate();"/>
                             <%
                            boolean applicationComponentFound = CarbonUIUtil.isContextRegistered(config, "/application/");
                            if (applicationComponentFound) {
                            %>
                            <input type="button" class="button"
                                       onclick="javascript:location.href='../application/configure-service-provider.jsp?spName=<%=Encode.forUriComponent(applicationSPName)%>'"
                                   value="<fmt:message key='cancel'/>"/>
                            <% } else { %>

                            <input type="button" class="button"
                                       onclick="javascript:location.href='index.jsp?region=region1&item=oauth_menu&ordinal=0'"
                                   value="<fmt:message key='cancel'/>"/>
                            <%} %>

                        </td>
                    </tr>
                    </tbody>
                </table>

            </form>
        </div>
    </div>
</fmt:bundle>

