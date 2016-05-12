jQuery(function() {
    var getQueryString = function(element) {
        var href = jQuery(element).attr('href');
        if (!href) return '';
        var questionMarkIndex = href.indexOf('?');
        if (!questionMarkIndex) return '';
        return href.substring(questionMarkIndex+1);
    };

    var showModal = function(lifecycle, lifecycleDesc, triggeringObject) {
        var queryString = getQueryString(triggeringObject);
        var constituency = '';

        var uri = window.location.href.split('/');
        for (var i = 0; i < uri.length; i++) {
            if (uri[i] === 'c') {
                constituency = '/c/' + uri[i+1];
                break;
            }
        }

        jQuery.get(
            RT.Config.WebHomePath + '/RTIR' + constituency + '/Helpers/CreateInRTIRQueueModal?Lifecycle=' + lifecycle + '&LifecycleDesc=' + lifecycleDesc + '&' + queryString,
            function(html) {
                // If there's only one queue, just create a ticket in it and skip the modal
                var queues = jQuery(html).find("select[name='Queue'] > option");
                if (queues.length === 1) {
                    window.location.href = RT.Config .WebHomePath + '/RTIR/Create.html?Queue=' + queues.first().val() + '&' + queryString;
                     return;
                }

                jQuery("<div class='modal'></div>")
                    .append(html).appendTo("body")
                    .bind('modal:close', function(ev,modal) { modal.elm.remove(); })
                    .modal();
            }
        );
    };

    var showReportsModal = function(e) {
        e.preventDefault();
        showModal('incident_reports', 'report', this);
    };

    var showInvestigationsModal = function(e) {
        e.preventDefault();
        showModal('investigations', 'investigation', this);
    };

    var showBlocksModal = function(e) {
        e.preventDefault();
        showModal('blocks', 'block', this);
    };

    var showIncidentsModal = function(e) {
        e.preventDefault();
        showModal('incidents', 'incident', this);
    };

    jQuery("#reports-create").click(showReportsModal);
    jQuery("#investigations-launch").click(showInvestigationsModal);
    jQuery("#blocks-create").click(showBlocksModal);
    jQuery("#incidents-create").click(showIncidentsModal);
    jQuery("#create-incident").click(showIncidentsModal);

    jQuery(".create_child_incident_reports").click(showReportsModal);
    jQuery(".create_child_investigations").click(showInvestigationsModal);
    jQuery(".create_child_blocks").click(showBlocksModal);
});
