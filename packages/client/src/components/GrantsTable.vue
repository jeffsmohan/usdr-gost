<template>
  <section class="container-fluid grants-table-container">
    <b-row class="my-3" v-if="showSearchControls">
      <div class="ml-3">
        <SavedSearchPanel :isDisabled="loading" />
      </div>
      <div class="ml-1">
        <SearchPanel :isDisabled="loading" ref="searchPanel" :search-id="Number(editingSearchId)" @filters-applied="paginateGrants" />
      </div>
    </b-row>
    <b-row  class="grants-table-title-control">
      <b-col v-if="showSearchControls" >
        <SearchFilter :isDisabled="loading" :filterKeys="searchFilters" @filter-removed="clearSearch" />
      </b-col>
      <b-col align-self="end" v-if="!showSearchControls">
        <h2 class="mb-0">{{ searchTitle }}</h2>
      </b-col>
      <b-col class="d-flex justify-content-end">
        <b-button @click="exportCSV" :disabled="loading" variant="outline-primary" size="sm">
          <b-icon icon="download" class="mr-2" aria-hidden="true" />Export to CSV</b-button>
      </b-col>
    </b-row>
    <b-row align-v="center">
      <b-col cols="12">
        <b-table id="grants-table" hover responsive stacked="sm" :items="formattedGrants"
          :fields="fields.filter(field => !field.hideGrantItem)" selectable striped :sort-by.sync="orderBy"
          :sort-desc.sync="orderDesc" :no-local-sorting="true" :bordered="true" select-mode="single" :busy="loading"
          :tbody-tr-attr="{'data-dd-action-name': 'grant search result'}"
          @row-selected="onRowSelected" @row-clicked="onRowClicked" show-empty emptyText="No matches found">
          <template #cell(award_ceiling)="row">
            <p> {{ formatMoney(row.item.award_ceiling) }}</p>
          </template>
          <template #table-busy>
            <div class="text-center text-info my-2" style="height: 1200px;">
              <b-spinner class="align-middle"></b-spinner>
              <strong> Loading...</strong>
            </div>
          </template>
          <template #empty="scope">
            &emsp;
            &emsp;
            <div class="text-center">
              <p class="empty-text"><strong>{{ scope.emptyText }}</strong></p>
              <div v-if="showSearchControls">
              <p class="empty-text">Tip: Broaden your search or adjust your keywords for more results</p>
              &nbsp;
              <p><a @click="initEditSearch(searchId);" class="link">
                  Edit Search Criteria
                </a></p>
              </div>
            </div>
          </template>
        </b-table>
      </b-col>
    </b-row>
    <b-row class="grants-table-pagination">
      <b-col cols="11" class="grants-table-pagination-component">
        <b-pagination
          class="m-0"
          v-model="currentPage"
          :total-rows="totalRows"
          :per-page="perPage"
          first-text="First"
          prev-text="Prev"
          next-text="Next"
          last-text="Last"
          aria-controls="grants-table" />
          <div class="my-1 rounded py-1 px-2 page-item">{{ totalRows }} total grant{{ totalRows == 1 ? '' : 's' }}</div>
      </b-col>
    </b-row>
    <GrantDetailsLegacy v-if="!newGrantsDetailPageEnabled" :selected-grant.sync="selectedGrant" />
  </section>
</template>

<script>
import { mapActions, mapGetters } from 'vuex';
import { newTerminologyEnabled, newGrantsDetailPageEnabled } from '@/helpers/featureFlags';
import { datadogRum } from '@datadog/browser-rum';
import { titleize } from '../helpers/form-helpers';
import GrantDetailsLegacy from './Modals/GrantDetailsLegacy.vue';
import SearchPanel from './Modals/SearchPanel.vue';
import SavedSearchPanel from './Modals/SavedSearchPanel.vue';
import SearchFilter from './SearchFilter.vue';

export default {
  components: {
    GrantDetailsLegacy, SearchPanel, SavedSearchPanel, SearchFilter,
  },
  props: {
    showInterested: Boolean,
    showRejected: Boolean,
    showResult: Boolean,
    showAssignedToAgency: String,
    showSearchControls: {
      type: Boolean,
      default: true,
    },
    searchTitle: {
      type: String,
      default: '',
    },
  },
  data() {
    return {
      perPage: 50,
      currentPage: 1,
      loading: false,
      fields: [
        {
          key: 'title',
        },
        {
          key: 'viewed_by',
        },
        {
          key: 'interested_agencies',
          label: `Interested ${newTerminologyEnabled() ? 'Teams' : 'Agencies'}`,
        },
        {
          // opportunity_status
          key: 'status',
          hideGrantItem: this.hideGrantItems,
        },
        {
          key: 'opportunity_category',
          hideGrantItem: this.hideGrantItems,
        },
        {
          key: 'cost_sharing',
        },
        {
          key: 'award_ceiling',
          sortable: true,
        },
        {
          key: 'open_date',
          sortable: true,
        },
        {
          key: 'close_date',
          sortable: true,
        },
      ],
      selectedGrant: null,
      selectedGrantIndex: null,
      orderBy: '',
      orderDesc: false,
      searchId: null,
    };
  },
  mounted() {
    document.addEventListener('keyup', this.changeSelectedGrantIndex);
    this.setup();
  },
  computed: {
    ...mapGetters({
      grants: 'grants/grants',
      grantsPagination: 'grants/grantsPagination',
      agency: 'users/agency',
      selectedAgency: 'users/selectedAgency',
      activeFilters: 'grants/activeFilters',
      selectedSearchId: 'grants/selectedSearchId',
      editingSearchId: 'grants/editingSearchId',
    }),
    totalRows() {
      return this.grantsPagination ? this.grantsPagination.total : 0;
    },
    lastPage() {
      return this.grantsPagination ? this.grantsPagination.lastPage : 0;
    },
    formattedGrants() {
      const DAYS_TO_MILLISECS = 24 * 60 * 60 * 1000;
      const warningThreshold = (this.agency.warning_threshold || 30) * DAYS_TO_MILLISECS;
      const dangerThreshold = (this.agency.danger_threshold || 15) * DAYS_TO_MILLISECS;
      const now = new Date();
      const generateTitle = (t) => {
        const txt = document.createElement('textarea');
        txt.innerHTML = t;
        return txt.value;
      };
      return this.grants.map((grant) => ({
        ...grant,
        title: generateTitle(grant.title),
        interested_agencies: grant.interested_agencies
          .map((v) => v.agency_abbreviation)
          .join(', '),
        viewed_by: grant.viewed_by_agencies
          .map((v) => v.agency_abbreviation)
          .join(', '),
        status: grant.opportunity_status,
        award_ceiling: grant.award_ceiling,
        open_date: new Date(grant.open_date).toLocaleDateString('en-US', { timeZone: 'UTC' }),
        close_date: new Date(grant.close_date).toLocaleDateString('en-US', { timeZone: 'UTC' }),
        _cellVariants: (() => {
          const diff = new Date(grant.close_date) - now;
          if (diff <= dangerThreshold) {
            return { close_date: 'danger' };
          }
          if (diff <= warningThreshold) {
            return { close_date: 'warning' };
          }
          return {};
        })(),
      }));
    },
    searchFilters() {
      return this.activeFilters;
    },
    newGrantsDetailPageEnabled() {
      return newGrantsDetailPageEnabled();
    },
  },
  watch: {
    selectedAgency() {
      this.setup();
    },
    currentPage() {
      if (this.loading) {
        return;
      }
      this.paginateGrants();
    },
    orderBy() {
      if (this.loading) {
        return;
      }
      this.paginateGrants();
    },
    orderDesc() {
      if (this.loading) {
        return;
      }
      this.paginateGrants();
    },
    selectedGrantIndex() {
      this.changeSelectedGrant();
    },
    // when we fetch grants, refresh selectedGrant reference
    grants() {
      this.changeSelectedGrant();
    },
    selectedSearchId() {
      this.loading = true;
      this.searchId = (this.selectedSearchId === null || Number.isNaN(this.selectedSearchId)) ? null : Number(this.selectedSearchId);
      const filterKeys = this.activeFilters.map((f) => f.key);
      if (this.searchId !== null && (filterKeys.includes('includeKeywords') || filterKeys.includes('excludeKeywords'))) {
        // only if include/exclude keywords are selected
        this.orderBy = 'rank';
        this.orderDesc = false;
      } else {
        this.orderBy = 'open_date';
        this.orderDesc = true;
      }
      this.paginateGrants();
    },
  },
  methods: {
    ...mapActions({
      fetchGrants: 'grants/fetchGrantsNext',
      navigateToExportCSV: 'grants/exportCSV',
      clearSelectedSearch: 'grants/clearSelectedSearch',
      initEditSearch: 'grants/initEditSearch',
      applyFilters: 'grants/applyFilters',
    }),
    setup() {
      this.clearSelectedSearch();
      this.paginateGrants();
    },
    clearSearch() {
      this.loading = true;
      this.orderBy = 'open_date';
      this.orderDesc = true;
    },
    titleize,
    async paginateGrants() {
      try {
        if (!this.searchId) {
          // apply custom filters based on props
          await this.applyFilters({
            reviewStatus: [
              `${this.showInterested ? 'Interested' : ''}`,
              `${this.showResult ? 'Applied' : ''}`,
              `${this.showRejected ? 'Not Applying' : ''}`,
              `${this.showAssignedToAgency ? 'Assigned' : ''}`,
            ].filter((r) => r),
          });
        }
        this.loading = true;
        await this.fetchGrants({
          perPage: this.perPage,
          currentPage: this.currentPage,
          orderBy: this.orderBy,
          orderDesc: this.orderDesc,
          showInterested: this.showInterested,
          showResult: this.showResult,
          showRejected: this.showRejected,
          assignedToAgency: this.showAssignedToAgency,
        });
      } catch (e) {
        this.notifyError();
        console.log(e);
      } finally {
        this.loading = false;
      }
    },
    notifyError() {
      this.$bvToast.toast('We encountered an error while retrieving grants data. For the most accurate results please refresh the page and try again.', {
        title: 'Something went wrong',
        variant: 'danger',
        solid: true,
        noAutoHide: true,
        toaster: 'b-toaster-top-center',
      });
    },
    onRowClicked(item) {
      if (!newGrantsDetailPageEnabled()) {
        return;
      }
      this.$router.push(`grant/${item.grant_id}`);
      datadogRum.addAction('view grant details', { grant: item });
    },
    onRowSelected(items) {
      const [row] = items;
      if (row) {
        const grant = this.grants.find((g) => row.grant_id === g.grant_id);
        this.selectedGrant = grant;
        this.selectedGrantIndex = this.grants.findIndex(
          (g) => row.grant_id === g.grant_id,
        );
      }
    },
    changeSelectedGrant() {
      if (this.selectedGrant) {
        const grant = this.grants[this.selectedGrantIndex];
        this.onRowSelected([grant]);
      }
    },
    // able to navigate through grants using left and right arrow keys, when dialog is selected
    changeSelectedGrantIndex(event) {
      if (event.keyCode === 37) {
        // left key
        if (this.currentPage === 1 && this.selectedGrantIndex === 0) {
          return;
        }
        if (this.currentPage !== 1 && this.selectedGrantIndex === 0) {
          // fetch previous page of grants
          this.currentPage -= 1;
          this.selectedGrantIndex = 0;
          return;
        }
        this.selectedGrantIndex -= 1;
      } else if (event.keyCode === 39) {
        // right key
        if (this.currentPage === this.lastPage) {
          return;
        }
        if (this.selectedGrantIndex + 1 === this.perPage) {
          // fetch next page of grants
          this.currentPage += 1;
          this.selectedGrantIndex = 0;
          return;
        }
        this.selectedGrantIndex += 1;
      }
    },
    async grantUpdated() {
      await this.paginateGrants();
      const grant = this.grants.find(
        (g) => this.selectedGrant.grant_id === g.grant_id,
      );
      this.selectedGrant = grant;
      this.selectedGrantIndex = this.grants.findIndex(
        (g) => this.selectedGrant.grant_id === g.grant_id,
      );
    },
    exportCSV() {
      this.navigateToExportCSV({
        perPage: this.perPage,
        currentPage: this.currentPage,
        orderBy: this.orderBy,
        orderDesc: this.orderDesc,
        showInterested: this.showInterested,
        showResult: this.showResult,
        showRejected: this.showRejected,
        assignedToAgency: this.showAssignedToAgency,
      });
    },
    formatMoney(value) {
      if (value === undefined || value === null) {
        return '';
      }
      const res = Number(value).toLocaleString('en-US', {
        minimumFractionDigits: 2,
        maximumFractionDigits: 2,
        style: 'currency',
        currency: 'USD',
      });
      return (`${res}`);
    },
  },
};
</script>
<style>
.empty-text {
  margin: 2px;
}

.grants-table-container {
  padding-left: 15px;
  padding-right: 15px;
}
/* set first columnheader th to 300px*/
#grants-table th:nth-child(1) {
  width: 300px;
}
.grants-table-title-control {
  padding-bottom: .75rem;
}
.grants-table-pagination {
  padding-bottom: .75rem;
}
.grants-table-pagination-component {
  display: flex;
  justify-content: left;
  align-items: center;
}
</style>
