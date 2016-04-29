jQuery(function() {
    var getQueryString = function(element) {
        var href = jQuery(element).attr('href');
        if (!href) return '';
        var questionMarkIndex = href.indexOf('?');
        if (!questionMarkIndex) return '';
        return href.substring(questionMarkIndex+1);
    };

    var showModal = function(lifecycle, lifecycleDesc) {
        var queryString = getQueryString(this);
        jQuery.get(
            RT.Config.WebHomePath + '/RTIR/Helpers/CreateInRTIRQueueModal?Lifecycle=' + lifecycle + '&LifecycleDesc=' + lifecycleDesc + '&' + queryString,
            function(html) {
                // If there's only one queue, just create a ticket in it and skip the modal
                var queues = jQuery(html).find("select[name='Queue'] > option");
                if (queues.length === 1) {
                    window.location.href = RT.Config .WebHomePath + '/RTIR/Create.html?Queue=' + queues.first().val();
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
        showModal('incident_reports', 'report');
    };

    var showInvestigationsModal = function(e) {
        e.preventDefault();
        showModal('investigations', 'investigation');
    };

    var showBlocksModal = function(e) {
        e.preventDefault();
        showModal('blocks', 'block');
    };

    var showIncidentsModal = function(e) {
        e.preventDefault();
        showModal('incidents', 'incident');
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
