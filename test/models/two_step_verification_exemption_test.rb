require "test_helper"

class TwoStepVerificationExemptionTest < ActiveSupport::TestCase
  setup do
    @today = Time.zone.today
  end

  context "validation" do
    should "be valid if a reason and a valid expiry date are provided" do
      exemption = build(:two_step_verification_exemption)
      assert exemption.valid?
    end

    should "be invalid if no reason is provided]" do
      exemption = build(:two_step_verification_exemption, reason: nil)
      assert_not exemption.valid?
      assert_includes exemption.errors[:reason], "must be provided"
    end

    should "be invalid if blank reason is provided]" do
      exemption = build(:two_step_verification_exemption, reason: "")
      assert_not exemption.valid?
      assert_includes exemption.errors[:reason], "must be provided"
    end

    should "be invalid if none of the expiry date fields are provided" do
      exemption = build(:two_step_verification_exemption, expiry_day: nil, expiry_month: nil, expiry_year: nil)
      assert_not exemption.valid?
      assert_includes exemption.errors[:expiry_date], "must be provided"
    end

    should "be invalid if all of the expiry date fields are blank" do
      exemption = build(:two_step_verification_exemption, expiry_day: "", expiry_month: "", expiry_year: "")
      assert_not exemption.valid?
      assert_includes exemption.errors[:expiry_date], "must be provided"
    end

    should "be invalid if any of the expiry date fields are not provided" do
      exemption = build(:two_step_verification_exemption, expiry_day: nil, expiry_year: nil)
      assert_not exemption.valid?
      assert_includes exemption.errors[:expiry_date], "day must be provided"
      assert_includes exemption.errors[:expiry_date], "year must be provided"
    end

    should "be invalid if some of the expiry date fields are blank" do
      exemption = build(:two_step_verification_exemption, expiry_day: "", expiry_month: "")
      assert_not exemption.valid?
      assert_includes exemption.errors[:expiry_date], "day must be provided"
      assert_includes exemption.errors[:expiry_date], "month must be provided"
    end

    should "be invalid if the expiry date is not in the future" do
      exemption = build(:two_step_verification_exemption, expiry_day: @today.day, expiry_month: @today.month, expiry_year: @today.year)
      assert_not exemption.valid?
      assert_includes exemption.errors[:expiry_date], "must be in the future"
    end

    should "be invalid if the expiry date is not a valid date" do
      exemption = build(:two_step_verification_exemption, expiry_day: 31, expiry_month: 2, expiry_year: @today.year + 1)
      assert_not exemption.valid?
      assert_includes exemption.errors[:expiry_date], "must be a real date"
    end
  end

  context ".from_user" do
    should "build exemption from attributes on a user" do
      user = build(:user, reason_for_2sv_exemption: "reason", expiry_date_for_2sv_exemption: @today)
      exemption = TwoStepVerificationExemption.from_user(user)

      assert_equal "reason", exemption.reason
      assert_equal @today.day.to_s, exemption.expiry_day
      assert_equal @today.month.to_s, exemption.expiry_month
      assert_equal @today.year.to_s, exemption.expiry_year
    end

    should "build exemption from attributes on a user even when they are nil" do
      user = build(:user, reason_for_2sv_exemption: nil, expiry_date_for_2sv_exemption: nil)
      exemption = TwoStepVerificationExemption.from_user(user)

      assert_nil exemption.reason
      assert_nil exemption.expiry_day
      assert_nil exemption.expiry_month
      assert_nil exemption.expiry_year
    end
  end

  context ".from_params" do
    should "build exemption from permitted controller params" do
      params = ActionController::Parameters.new(
        "exemption" => {
          "reason" => "reason",
          "expiry_date" => { "day" => "23", "month" => "11", "year" => "2025" },
        },
      )
      .require(:exemption).permit(:reason, expiry_date: %i[day month year])

      exemption = TwoStepVerificationExemption.from_params(params)

      assert_equal "reason", exemption.reason
      assert_equal "23", exemption.expiry_day
      assert_equal "11", exemption.expiry_month
      assert_equal "2025", exemption.expiry_year
    end
  end
end
