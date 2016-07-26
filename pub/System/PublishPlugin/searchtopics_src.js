jQuery(function($){
    foswiki.searchtopic = function(){
        var $this = $(this);

        if(!$this.find('input[name="topiclistCB"]').length) return;

        var topics = '';
        var pdfs = '';
        var regex = new RegExp("\.pdf$");
        $this.find('input[name="topiclistCB"]:checked').each(function(idx){
            var val = $(this).val();
            if(regex.exec(val)) {
                if(pdfs) pdfs += ',';
                pdfs += val.replace(/,/g, '\\,');
            } else {
                if(topics) topics += ',';
                topics += val;
            }
        });
        $this.find('input[name="topiclist"]').val(topics);
        $this.find('input[name="catpdf"]').val(pdfs);
    };
    $('.selectAllTopics').livequery(function(){$(this).click(function(){
        $('form[name="publish"]').find('input[name="topiclistCB"]').prop('checked', true);
        return false;
    });});
    $('.selectNoTopics').livequery(function(){$(this).click(function(){
        $('form[name="publish"]').find('input[name="topiclistCB"]').prop('checked', false);
        return false;
    });});
    $('form[name="publish"] .topicselection .ajaxOnChange').livequery(function(){$(this).change(function(){
        var $this = $(this);
        var $div = $this.closest('.topicselection');
        $div.block({message:''});
        var viewtemplate = $('input[name="viewtemplate"]:first').val();
        var ajaxOnChange = '';
        $div.find('.ajaxOnChange').each(function(){
            var $this = $(this);
            ajaxOnChange += '&'+$this.prop('name')+'='+encodeURIComponent($this.val());
        });
        $div.load(foswiki.getPreference('SCRIPTURLPATH')+'/rest'+foswiki.getPreference('SCRIPTSUFFIX')+'/RenderPlugin/template?name='+encodeURIComponent(viewtemplate)+'&expand=topicselection&render=1&topic='+encodeURIComponent(foswiki.getPreference('WEB')+'.'+foswiki.getPreference('TOPIC'))+ajaxOnChange);
    })});
    $('form[name="publish"] select[name="formselection"]').livequery(function(){$(this).change(function(){
        var $this = $(this);
        var $div = $this.closest('.topicselection');
        $div.block({message:''});
        var viewtemplate = $('input[name="viewtemplate"]:first').val();
        $div.load(foswiki.getPreference('SCRIPTURLPATH')+'/rest'+foswiki.getPreference('SCRIPTSUFFIX')+'/RenderPlugin/template?name='+encodeURIComponent(viewtemplate)+'&expand=topicselection&render=1&topic='+encodeURIComponent(foswiki.getPreference('WEB')+'.'+foswiki.getPreference('TOPIC'))+'&selected='+encodeURIComponent($this.val()));
    })});
});
