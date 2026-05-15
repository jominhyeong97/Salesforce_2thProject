List<Lead> leadsToRefresh = [
    SELECT Id
    FROM Lead
];

if (!leadsToRefresh.isEmpty()) {
    update leadsToRefresh;
}

System.debug('Aqua lead automation backfill complete: ' + leadsToRefresh.size());
