# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Devise::SessionsController, type: :controller do
  let(:admin) { Admin.create(email: 'admin@example.com', password: 'password', password_confirmation: 'password') }

  describe 'GET #new' do
    it 'renders the sign-in form' do
      @request.env['devise.mapping'] = Devise.mappings[:admin]
      get :new
      expect(response).to render_template(:new)
    end
  end

  describe 'POST #create' do
    context 'with valid credentials' do
      it 'signs in the admin and redirects to the admin page' do
        @request.env['devise.mapping'] = Devise.mappings[:admin]
        post :create, params: { admin: { email: admin.email, password: admin.password } }
        expect(response).to redirect_to('/admin')
        expect(controller.current_admin).to eq(admin)
      end
    end

    context 'with invalid credentials' do
      it 'renders the sign-in form again' do
        @request.env['devise.mapping'] = Devise.mappings[:admin]
        post :create, params: { admin: { email: 'invalid@example.com', password: 'wrong_password' } }
        expect(response).to have_http_status(401)
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'signs out the admin and redirects to the root page' do
      @request.env['devise.mapping'] = Devise.mappings[:admin]
      sign_in admin
      delete :destroy
      expect(response).to redirect_to('/')
      expect(controller.current_admin).to be_nil
    end
  end
end
