require 'spec_helper'

describe Chemistry do

  describe "test", :current => true do
    let(:specimen_1) { FactoryGirl.create(:specimen) }
    let(:analysis_1) { FactoryGirl.create(:analysis, specimen: specimen_1) }
    let(:analysis_2) { FactoryGirl.create(:analysis, specimen: specimen_1) }
    let(:analysis_3) { FactoryGirl.create(:analysis, specimen: specimen_1) }    
    let(:chemistry) { FactoryGirl.create(:chemistry, analysis: analysis_1, measurement_item: measurement_item, unit: unit, value: value) }
    let(:chemistry_1) { FactoryGirl.create(:chemistry, analysis: analysis_2, measurement_item: measurement_item, unit: unit_2, value: value) }
    let(:chemistry_2) { FactoryGirl.create(:chemistry, analysis: analysis_3, measurement_item: measurement_item, unit: unit, value: value) }
    let(:measurement_item) { FactoryGirl.create(:measurement_item, unit: unit, display_in_html: display_in_html, nickname: nickname) }
    let(:measurement_item_2) { FactoryGirl.create(:measurement_item, unit: unit, display_in_html: display_in_html, nickname: nickname) }
    let(:unit) { FactoryGirl.create(:unit, :name => 'cg/g', :conversion => 100) }
    let(:unit_2) { FactoryGirl.create(:unit, :name => 'ug/g', :conversion => 1000000) }

    let(:value) { 1 }
    let(:display_in_html) { "HTML" }
    let(:nickname) { "nickname" }
    before do
      chemistry
      chemistry_1
      chemistry_2
      #chem = Chemistry.joins(:measurement_item, :unit).where(measurement_items: {nickname: measurement_item.nickname}).select(:value, "units.name").first
      chems = Chemistry.joins(:measurement_item, :unit).where(measurement_item_id: measurement_item.id).select("chemistries.id, value, value / units.conversion as value_in_parts, units.name as unit_name ")
      chems.each do |chem|
        p chem.value
        p chem.unit_name
        p chem.value_in_parts
      end
      summary = Chemistry.search_with_measurement_item_id(measurement_item.id).with_unit.select_summary_value_in_parts[0]
      p "n: #{summary.count}"
      p "max: #{summary.max}"
      p "min: #{summary.min}"
      p "avg: #{summary.avg}"


    end
    it {
      expect(Chemistry.with_measurement_item.all).not_to be_empty
    }
  end

  describe "#specimen" do
    subject { chemistry.specimen }
    let(:specimen_1) { FactoryGirl.create(:specimen) }
    let(:analysis_1) { FactoryGirl.create(:analysis, specimen: specimen_1) }
    let(:chemistry) { FactoryGirl.create(:chemistry, analysis: analysis_1, measurement_item: measurement_item, unit: unit, value: value) }
    let(:measurement_item) { FactoryGirl.create(:measurement_item, unit: unit, display_in_html: display_in_html, nickname: nickname) }
    let(:unit) { FactoryGirl.create(:unit) }
    let(:value) { 1 }
    let(:display_in_html) { "HTML" }
    let(:nickname) { "nickname" }
    it {
      expect(subject).to be_eql(specimen_1)
    }
  end

  describe "#display_name" do
    subject { chemistry.display_name }
    let(:chemistry) { FactoryGirl.build(:chemistry, measurement_item: measurement_item, unit: unit, value: value) }
    let(:measurement_item) { FactoryGirl.create(:measurement_item, unit: unit, display_in_html: display_in_html, nickname: nickname) }
    let(:unit) { FactoryGirl.create(:unit) }
    let(:value) { 1 }
    let(:display_in_html) { "HTML" }
    let(:nickname) { "nickname" }
    context "measurement_item.display_in_html is present" do
      it { expect(subject).to eq "HTML: 1.00" }
    end
    context "measurement_item.display_in_html is nil" do
      let(:display_in_html) { nil }
      it { expect(subject).to eq "nickname: 1.00" }
    end
  end
  
  describe "#unit_conversion_value" do
    subject { chemistry.unit_conversion_value(unit_name, scale) }
    let(:chemistry) { FactoryGirl.create(:chemistry, unit: unit, value: value) }
    let(:unit) { FactoryGirl.create(:unit, name: "gram_per_gram", conversion: 1) }
    let(:value) { 10 }
    let(:unit_name) { "carat" }
    let(:scale) { 1 }
    before do
      unit
      Alchemist.setup
      Alchemist.register(:mass, unit.name.to_sym, 1.to_d / unit.conversion)
    end
    context "scale is 1" do
      context "unit_name is 'carat'" do
        it { expect(subject).to eq 50.0 }# 5carat = 1gram
      end
      context "unit_name is 'ounce'" do
        let(:unit_name) { "ounce" }
        it { expect(subject).to eq 0.4 }# 1ounce = 28.34952gram
      end
    end
    context "scale is 2" do
      let(:scale) { 2 }
      context "unit_name is 'carat'" do
        it { expect(subject).to eq 50.00 }
      end
      context "unit_name is 'ounce'" do
        let(:unit_name) { "ounce" }
        it { expect(subject).to eq 0.35 }
      end
    end
    context "scale is 3" do
      let(:scale) { 3 }
      context "unit_name is 'carat'" do
        it { expect(subject).to eq 50.000 }
      end
      context "unit_name is 'ounce'" do
        let(:unit_name) { "ounce" }
        it { expect(subject).to eq 0.353 }
      end
      context "unit_name is 'centi_gram_per_gram'" do
        let(:unit) { FactoryGirl.create(:unit, name: "centi_gram_per_gram", conversion: 100) }
        let(:value) { 51.23 }
        let(:unit_name) { "centi_gram_per_gram" }
        it { expect(subject).to eq 51.23 }
      end
    end
    context "scale is 0" do
      let(:scale) { 0 }
      context "unit_name is 'carat'" do
        it { expect(subject).to eq 50 }
      end
      context "unit_name is 'ounce'" do
        let(:unit_name) { "ounce" }
        it { expect(subject).to eq 0 }
      end
    end
    context "scale is nil" do
      let(:scale) { nil }
      context "unit_name is 'carat'" do
        it { expect(subject).to eq 50 }
      end
      context "unit_name is 'ounce'" do
        let(:unit_name) { "ounce" }
        it { expect(subject).to be_within(0.001).of(0.3527) }
      end
    end
  end

end
