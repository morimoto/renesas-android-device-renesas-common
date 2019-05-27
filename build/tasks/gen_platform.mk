
ifneq (,$(filter $(TARGET_PRODUCT), salvator ulcb kingfisher))

$(PRODUCT_OUT)/platform.txt:
	echo $(TARGET_BOARD_PLATFORM) > $@

droidcore: $(PRODUCT_OUT)/platform.txt

endif
