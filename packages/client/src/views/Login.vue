<template>
  <b-card
    no-body
    tag="div"
    style="max-width: 26rem; margin-top: 11rem"
    class="mx-auto border-0"
  >
    <b-card-img
        :src="require('../assets/usdr_logo_standard_wide.svg')"
        style="max-width: 14rem"
        alt="United States Digital Response logo"
        class="mx-auto mb-3"
        top
      ></b-card-img>
    <b-card-text class="mt-4 p-3 dropshadow-card">
      <h1 class="h3 my-4">Log in to Federal Grant Finder</h1>
      <p class="mb-4">Enter your email to receive a one-time login link.</p>
      <form @submit="login">
        <div>
          <label for="email">Email</label>
          <input
            class="form-control mb-4"
            id="email"
            name="email"
            placeholder="Email address"
            v-model="email"
            autofocus
          />
        </div>
        <div
          class="d-flex justify-content-center"
        >
          <b-button
            variant="primary"
            class="btn-block"
            type="Submit"
            @click="login"
          >
            Send me the link
          </b-button>
        </div>
      </form>
      <div :class="messageClass" class="mt-3" v-if="message">{{ message }}</div>
      <hr class="my-4"/>
      <p>
        Don't have an account? Please fill out
        <a href="https://form.jotform.com/201195733501145" target="_blank">USDR's request form</a>
        and indicate you'd like to create one.
      </p>
      <p>Need help? <a href="mailto:grants-helpdesk@usdigitalresponse.org?subject=Federal Grant Finder Login Issue">Contact us</a> for support.</p>
    </b-card-text>
  </b-card>
</template>

<script>
/* eslint-disable import/no-unresolved */
import { apiURL } from '@/helpers/fetchApi';
import _ from 'lodash-checkit';

export default {
  name: 'Login',
  data() {
    const message = _.get(this, '$route.query.message', null);
    const messageClass = message ? 'alert alert-danger' : '';
    const redirectTo = _.get(this, '$route.query.redirect_to', null);
    return {
      email: '',
      message,
      messageClass,
      redirectTo,
    };
  },
  methods: {
    login(e) {
      e.preventDefault();
      if (!this.email) {
        this.message = 'Email cannot be blank';
        this.messageClass = 'alert alert-danger';
        return;
      }
      if (!_.isEmail(this.email)) {
        this.message = `'${this.email}' is not a valid email address`;
        this.messageClass = 'alert alert-danger';
        return;
      }

      const bodyRaw = { email: this.email };
      if (this.redirectTo) {
        bodyRaw.redirect_to = this.redirectTo;
      }

      const body = JSON.stringify(bodyRaw);
      const headers = {
        'Content-Type': 'application/json',
      };
      let resStatus = 0;
      fetch(apiURL('/api/sessions'), { method: 'POST', headers, body })
        .then((r) => {
          resStatus = r.status;
          if (!r.ok) throw new Error(`login: ${r.statusText} (${r.status})`);
          return r;
        })
        .then((r) => r.json())
        .then((r) => {
          this.email = '';
          this.message = r.message;
          this.messageClass = r.success
            ? 'alert alert-success'
            : 'alert alert-danger';
        })
        .catch((err) => {
          this.message = resStatus === 500
            ? 'There was a problem at USDR. Try again in a minute or two, and if you still receive the same error, contact the USDR team.'
            : err.message;
          this.messageClass = 'alert alert-danger';
        });
    },
  },
};
</script>
