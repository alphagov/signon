class TwoStepVerificationExemptionsController < ApplicationController
  before_action :authenticate_user!, :load_and_authorize_user

  def edit; end

  def update
    error_string_or_parsed_params = parsed_params_or_error_string(params[:user])
    case error_string_or_parsed_params
    when String
      flash[:alert] = error_string_or_parsed_params
      redirect_to edit_two_step_verification_exemption_path(@user)
    else
      reason_for_2sv_exemption, valid_expiry_date = error_string_or_parsed_params
      @user.exempt_from_2sv(reason_for_2sv_exemption, current_user, valid_expiry_date)
      flash[:notice] = "User exempted from 2SV"
      redirect_to edit_user_path(@user)
    end
  end

private

  def parsed_params_or_error_string(user_params)
    if user_params[:reason_for_2sv_exemption].empty?
      "Reason for exemption must be provided"
    else
      begin
        expiry_date = parse_date_from_user_params(params[:user])
        if Time.zone.today >= expiry_date
          "Expiry date must be in the future"
        else
          [user_params[:reason_for_2sv_exemption], expiry_date]
        end
      rescue Date::Error
        "Expiry date is not a valid date"
      end
    end
  end

  def parse_date_from_user_params(user_params)
    date_part_params = ["(1i)", "(2i)", "(3i)"].map { |suffix| "expiry_date_for_2sv_exemption#{suffix}" }
    date_params = date_part_params.map { |param_name| user_params[param_name] }

    raise Date::Error if date_params.any?(&:nil?)

    date_string = date_params.join("/")
    Date.parse(date_string)
  end

  def load_and_authorize_user
    @user = User.find(params[:id])
    authorize @user, :exempt_from_two_step_verification?
  end
end
