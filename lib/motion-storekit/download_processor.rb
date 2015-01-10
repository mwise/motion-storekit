module MotionStoreKit

  class DownloadProcessor

    attr_reader :purchase_path

    def initialize(download, args = {})
      @error_ptr = Pointer.new(:object)
      @purchases_directory = args[:purchases_directory] || default_purchases_directory
      @verbose = args.fetch(:verbose, true)

      product_id = download.contentIdentifier
      contents_path = download.contentURL.path + "/Contents"
      @purchase_path = contents_path

      debug_download(download) if @verbose

      if args.fetch(:copy_to_documents, true)
        @purchase_path = create_purchase_directory(product_id)
        move_files_to_purchase_path(contents_path, @purchase_path, download.contentURL)
      end
      NSLog("Purchase path for #{product_id}: #{@purchase_path}") if @verbose
    end

    def self.process(download, args = {})
      self.new(download, args).purchase_path
    end

    private

    def create_purchase_directory(product_id)
      create_purchases_directory
      path = @purchases_directory + "/#{product_id}"
      if !filer.fileExistsAtPath(path)
        unless filer.createDirectoryAtPath(path,
          withIntermediateDirectories: true,
          attributes: nil,
          error: @error_ptr)
          log_error("Error: Unable to create purchase directory.")
        end
      end
      path
    end

    def create_purchases_directory
      if !filer.fileExistsAtPath(@purchases_directory)
        filer.createDirectoryAtPath(@purchases_directory,
        withIntermediateDirectories: true,
        attributes: nil,
        error: @error_ptr)
        exclude_purchases_directory_from_backup
      end
    end

    def default_purchases_directory
      documents_directory + "/Purchases"
    end

    def documents_directory
      @documents_directory ||= NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true)
        .objectAtIndex(0)
    end

    def exclude_purchases_directory_from_backup
      url = NSURL.fileURLWithPath(@purchases_directory)
      unless url.setResourceValue(NSNumber.numberWithBool(true),
        forKey: NSURLIsExcludedFromBackupKey,
        error: @error_ptr)
        log_error("Error: Unable to exclude purchases directory from backup.")
      end
    end

    def filer
      NSFileManager.defaultManager
    end

    def move_file_to_purchase_directory(file_path, purchase_path)
      purchase_file_path = "#{purchase_path}/#{file_path.lastPathComponent}"

      if filer.fileExistsAtPath(purchase_file_path)
        unless filer.removeItemAtPath(purchase_file_path,
          error: @error_ptr)
          log_error("Error: Unable to remove file path.")
        end
      end

      unless filer.moveItemAtPath(file_path,
        toPath: purchase_file_path,
        error: @error_ptr)
        log_error("Error: Unable to move file to path.")
      end
    end

    def move_files_to_purchase_path(contents_path, purchase_path, content_url)
      if files = filer.contentsOfDirectoryAtPath(contents_path, error:nil)
        files.each do |file|
          move_file_to_purchase_directory("#{contents_path}/#{file}", purchase_path)
        end
      end

      unless filer.removeItemAtURL(content_url, error: @error_ptr)
        log_error("Error cleaning up cached content URL.")
      end
    end

    def debug_download(download)
      NSLog "--- download info ---"
      NSLog "  contentIdentifier: #{download.contentIdentifier}"
      NSLog "  contentURL: #{download.contentURL.path}"
      NSLog "  contentLength: #{download.contentLength}"
      NSLog "  contentVersion: #{download.contentVersion}"
      NSLog "  downloadState: #{download.downloadState}"
      NSLog "  progress: #{download.progress}"
      NSLog "  timeRemaining: #{download.timeRemaining}"
      if download.error
        NSLog "  error: #{download.error}"
      end
      NSLog "\n"
    end

    def log_error(message)
      NSLog("#{message} error=#{@error_ptr.value.localizedDescription}")
    end

  end

end
