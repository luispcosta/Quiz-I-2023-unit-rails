# frozen_string_literal:true

require 'barby/barcode/code_128'
require 'barby/outputter/png_outputter'

class Barcode
  BARCODES_DIR = 'public/barcodes'

  def initializer(name)
    @name = name
  end

  def generate
    generate_bar_code unless barcode_exists?
    barcode_path(name)
  end

  private

  def generate_bar_code
    generate_barcodes_dir!
    barcode = Barby::Code128B.new(name)
    blob = Barby::PngOutputter.new(barcode).to_png
    save_barcode_to_dir!(blob)
  end

  def save_barcode_to_dir!(blob)
    File.open(barcode_path(name), 'wb') { |f| f.write blob }
  end

  def barcode_path(name)
    Rails.root.join(BARCODES_DIR, "#{name}.png")
  end

  def generate_barcodes_dir!
    FileUtils.mkdir_p(Rails.root.join(BARCODES_DIR))
  end
end
