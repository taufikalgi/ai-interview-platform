# frozen_string_literal: true

module Api
  module V1
    class AuthenticationController < ApiController
      skip_before_action :require_tenant!

      # POST /api/v1/auth/login
      def authenticate
        user = User.find_by(email: params[:email].to_s.downcase)

        # The credential check (has_secure_password) is the real security control.
        # Any valid account — admin or assessor/user — may obtain a token here.
        # Per P1-4 we deliberately removed the hard `role == 'admin'` gate that
        # previously made self-serve `user`-role signups dead-end at login.
        # Role-restricted endpoints should be gated per-action via
        # `authorize_auth_token!` instead of blocking login globally.
        return json_error('Invalid email or password', :unauthorized) unless user&.authenticate(params[:password])

        scheme = resolve_scheme
        token  = JsonWebToken.encode({ user_id: user.id, role: user.role, scheme: })

        json_response({ token:, user: { id: user.id, email: user.email, role: user.role } })
      end

      # POST /api/v1/auth/signup
      def signup
        user = User.new(
          email:    params[:email].to_s.downcase,
          password: params[:password],
          role:     params[:role].presence || 'user'
        )

        if user.save
          scheme = resolve_scheme
          token  = JsonWebToken.encode({ user_id: user.id, role: user.role, scheme: })
          json_response(
            { token:, user: { id: user.id, email: user.email, role: user.role } },
            :created
          )
        else
          json_error(user.errors.full_messages, :unprocessable_entity)
        end
      end

      private

      def resolve_scheme
        request.headers['X-Tenant-Scheme'].presence ||
          ActiveRecord::Base.connection.select_value(
            'SELECT scheme FROM organizations LIMIT 1'
          ) || 'test-corp'
      end
    end
  end
end
