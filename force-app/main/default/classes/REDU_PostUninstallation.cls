/**
 * @author      WDCi (Lean)
 * @date        July 2023
 * @group       Installation
 * @description Post uninstallation script
 * @changehistory
 */
global without sharing class REDU_PostUninstallation implements UninstallHandler {
    
    /**
     * @description Specifies the actions to be performed on uninstallation
     * @return void
     */
    global void onUninstall(UninstallContext ctx) {

        //add more uninstallation task here


        //email post installation script error to current user
        Map<String, Object> userBindParams = new Map<String, Object>();
        userBindParams.put('installerId', ctx.uninstallerID());

        String userSoql = 'SELECT Id, Email FROM User WHERE Id =: installerId';
        List<User> users = (List<User>) Database.queryWithBinds(userSoql, userBindParams, AccessLevel.SYSTEM_MODE);

        User u = users.get(0); 
        String toAddress= u.Email;
        String[] toAddresses = new String[]{toAddress};
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        mail.setToAddresses(toAddresses);
        mail.setReplyTo('support@wdcigroup.net');
        mail.setSenderDisplayName('WDCi Support');

        String subject = '';
        String body = '';

        try {
            subject = 'RIO Education V4: Package uninstall successful';
            body = 'Thanks for uninstalling the package.';

        } catch (Exception exp) {
            subject = 'RIO Education V4: Package uninstall failed';

            body = 'Unfortunately, the RIO Education V4 post uninstallation script failed. Please forward the following error to support@wdcigroup.net for further assistance.';
            body += '\nError message: ' + exp.getMessage();
            body += '\nLine number: ' + exp.getLineNumber();
            body += '\nStacktrace: ' + exp.getStackTraceString();
            
        } finally {

            mail.setSubject(subject);
            mail.setPlainTextBody(body);

            Messaging.sendEmail(new Messaging.Email[] { mail });
        }
    }

}