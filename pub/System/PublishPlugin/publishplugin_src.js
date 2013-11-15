jQuery(function($) {
    var $pform = $("form[name='publish']");
    if(!$pform.length) return;

    $pform.find("select[name='web']").change(function(){
        var $this = $(this);
        var web = $(this).val();
        if($.blockUI !== undefined) $.blockUI();
        window.location.replace(foswiki.getPreference('SCRIPTURL') + '/view' + foswiki.getPreference('SCRIPTSUFFIX') + '/' + foswiki.getPreference('WEB') + '/' + foswiki.getPreference('TOPIC') + '?web=' + encodeURIComponent(web));
    });

    if($pform.ajaxForm) $pform.ajaxForm({
        beforeSubmit: function(arr, $form, options) {
            if(StrikeOne !== undefined) {
                StrikeOne.submit($form[0]);
                for(var i = 0; i < arr.length; i++) {
                    var obj = arr[i];
                    if(obj.name = 'validation_key') {
                        obj.value = $form.find('input[name=validation_key]:first').attr('value');
                        break;
                    }
                }
            }
            if($.blockUI !== undefined) $.blockUI();
        },
        success: function(data) {
            if($.blockUI !== undefined) $.unblockUI();
            var $data = $(data);
            var $dTopic = $data.find('.foswikiTopic');
            if($pform.dialog !== undefined) {
                var $dialog = $('<div class="jqUIDialog {autoOpen: true, resizable: true, width: \''+$pform.closest('div').width()+'\', draggable: true, closeOnEscape: true}" title=""><div class="contents"></div><a class="jqUIDialogButton jqUIDialogClose {icon:\'ui-icon-circle-check\'}">Ok</a></div>');
                $dialog.find('.contents').replaceWith($dTopic);
                $('body').append($dialog.hide());
            } else {
                $('.foswikiTopic:first').replaceWith($dTopic);
            }
        }
    });
});

