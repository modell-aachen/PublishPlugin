jQuery(function($){
    $('form[name="publish"]').submit(function(){
        var $this = $(this);
        var topics = '';
        var pdfs = '';
        var regex = new RegExp("\.pdf$");
        $this.find('input[name="topiclistCB"]:checked').each(function(idx){
            var val = $(this).val();
            if(regex.exec(val)) {
                if(pdfs) pdfs += ',';
                pdfs += val;
            } else {
                if(topics) topics += ',';
                topics += val;
            }
        });
        $this.find('input[name="topiclist"]').val(topics);
        $this.find('input[name="catpdf"]').val(pdfs);
    });
    $('.selectAllTopics').click(function(){
        $('form[name="publish"]').find('input[name="topiclistCB"]').prop('checked', true);
        return false;
    });
    $('.selectNoTopics').click(function(){
        $('form[name="publish"]').find('input[name="topiclistCB"]').prop('checked', false);
        return false;
    });
    $('form[name="publish"] select[name="formselection"]').livequery(function(){$(this).change(function(){
        var $this = $(this);
        var $div = $this.closest('.topicselection');
        $div.block({message:''});
        var viewtemplate = $('input[name="viewtemplate"]:first').val();
        $div.load(foswiki.getPreference('SCRIPTURLPATH')+'/rest'+foswiki.getPreference('SCRIPTSUFFIX')+'/RenderPlugin/template?name='+encodeURIComponent(viewtemplate)+'&expand=topicselection&render=1&topic='+encodeURIComponent(foswiki.getPreference('WEB')+'.'+foswiki.getPreference('TOPIC'))+'&selected='+encodeURIComponent($this.val()));
    })});
});
