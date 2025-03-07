<template>
<section class="container-fluid">
  <b-row>
    <b-col class="m-2"><h2 class="h4">{{newTerminologyEnabled ? 'Organizations' : 'Tenants'}}</h2></b-col>
    <b-col></b-col>
    <b-col class="d-flex justify-content-end">
      <div>
        <b-button variant="primary" size="sm" @click="openAddOrganizationModal">Add</b-button>
      </div>
    </b-col>
  </b-row>
  <b-table sticky-header="600px" hover :items="formattedOrganizations" :fields="fields">
      <template #cell(display_name)="row">
        {{row.item.display_name}}
      </template>
      <template #cell(actions)="row">
      <b-button class="mr-1 border-0" size="sm" variant="outline-primary" @click="openEditOrganizationModal(row.item)">
        <b-icon icon="pencil-fill" aria-hidden="true"></b-icon>
      </b-button>
    </template>
  </b-table>
  <EditOrganizationModal :tenant.sync="editingOrganization"/>
  <AddOrganizationModal :showModal.sync="showAddOrganizationModal"/>
</section>
</template>

<script>

import { mapActions, mapGetters } from 'vuex';

import EditOrganizationModal from '@/components/Modals/EditOrganization.vue';
import AddOrganizationModal from '@/components/Modals/AddOrganization.vue';
import { newTerminologyEnabled } from '@/helpers/featureFlags';

export default {
  components: {
    EditOrganizationModal,
    AddOrganizationModal,
  },
  data() {
    return {
      fields: [
        { key: 'id', sortable: true, label: 'ID' },
        {
          key: 'display_name',
          sortable: true,
        },
        { key: 'actions', label: 'Actions' },
      ],
      showEditOrganizationModal: false,
      showAddOrganizationModal: false,
      editingOrganization: null,
    };
  },
  mounted() {
    this.setup();
  },
  computed: {
    ...mapGetters({
      organizations: 'tenants/tenants',
      selectedTeam: 'users/selectedAgency',
    }),
    newTerminologyEnabled() {
      return newTerminologyEnabled();
    },
    formattedOrganizations() {
      return this.organizations?.map((organization) => ({
        ...organization,
      }));
    },
  },
  watch: {
    selectedTeam() {
      this.setup();
    },
    showModal() {
      this.$bvModal.show('add-tenant-modal');
    },
  },
  methods: {
    ...mapActions({
      fetchOrganizations: 'tenants/fetchTenants',
    }),
    setup() {
      this.fetchOrganizations();
    },
    openEditOrganizationModal(tenant) {
      this.editingOrganization = tenant;
      this.showEditOrganizationModal = true;
    },
    openAddOrganizationModal() {
      this.showAddOrganizationModal = true;
    },
  },
};
</script>
