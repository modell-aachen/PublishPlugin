jQuery(function($) {
    var $pform = $("form[name='publish']");
    if(!$pform.length) return;

    $pform.find("select[name='web'],.reloadTopicList").change(function(){
        var params = '?web=' + $("[name='web']").val();
        $('.reloadTopicList').each(function() {
            var $this = $(this);
            var val = $this.val();
            var name = $this.attr('name');
            params += ';'+name + '=' + encodeURIComponent(val);
        });
        if($.blockUI !== undefined) $.blockUI();
        window.location.replace(foswiki.getPreference('SCRIPTURL') + '/view' + foswiki.getPreference('SCRIPTSUFFIX') + '/' + foswiki.getPreference('WEB') + '/' + foswiki.getPreference('TOPIC') + params);
    });

    if($pform.ajaxForm) $pform.ajaxForm({
        beforeSerialize: function($form, options) {
            if(StrikeOne !== undefined) {
                StrikeOne.submit($form[0]);
            }
            if($.blockUI !== undefined) $.blockUI();
            if(foswiki.searchtopic) foswiki.searchtopic.call($form);
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

