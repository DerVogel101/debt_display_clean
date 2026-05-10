import 'dart:typed_data';

import 'package:debt_display/generated/debt.pb.dart';
import 'package:debt_display/l10n/generated/app_localizations.dart';
import 'package:debt_display/state/auth_session_state.dart';
import 'package:debt_display/state/bill_creation_state.dart';
import 'package:debt_display/state/bill_list_state.dart';
import 'package:debt_display/state/navigation_state.dart';
import 'package:debt_display/state/recipient_group_state.dart';
import 'package:debt_display/theme/app_themes.dart';
import 'package:debt_display/ui/app_shared.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

const _ownerShareKey = -1;

class BillCreationSection extends StatefulWidget {
  const BillCreationSection({super.key, required this.isDesktop});

  final bool isDesktop;

  @override
  State<BillCreationSection> createState() => _BillCreationSectionState();
}

class _BillCreationSectionState extends State<BillCreationSection> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _tagSearchController = TextEditingController();
  final _tagTextController = TextEditingController();
  final _ownerPercentController = TextEditingController(text: '100');
  final _ownerAmountController = TextEditingController();
  final _percentControllers = <int, TextEditingController>{};
  final _shareAmountControllers = <int, TextEditingController>{};
  final _attachments = <_AttachmentDraft>[];
  final _selectedTags = <BillDraftTag>[];
  final _draftTags = <BillDraftTag>[];
  final _sharePercents = <int, double>{_ownerShareKey: 100};

  String? _currency;
  int? _selectedGroupId;
  String _tagEmoji = '🏷️';
  Color _tagColor = brandPrimary;
  bool _didResolveCurrency = false;
  bool _isPickingFile = false;
  bool _isPickingCamera = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<BillCreationState>().ensureLoaded();
      context.read<RecipientGroupState>().ensureLoaded();
      _syncShareControllers();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didResolveCurrency) {
      final locale = Localizations.localeOf(context);
      _currency =
          NumberFormat.simpleCurrency(locale: locale.toString()).currencyName ??
          'EUR';
      _didResolveCurrency = true;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _tagSearchController.dispose();
    _tagTextController.dispose();
    _ownerPercentController.dispose();
    _ownerAmountController.dispose();
    for (final controller in _percentControllers.values) {
      controller.dispose();
    }
    for (final controller in _shareAmountControllers.values) {
      controller.dispose();
    }
    for (final attachment in _attachments) {
      attachment.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = context.select<AuthSessionState, bool>(
      (state) => state.isAuthenticated,
    );
    final l10n = AppLocalizations.of(context);
    final state = context.watch<BillCreationState>();
    final groupState = context.watch<RecipientGroupState>();

    if (!isAuthenticated) {
      return _LoggedOutBillCreationSection(isDesktop: widget.isDesktop);
    }

    final groups = _ownedGroups(groupState);
    final selectedGroup = _selectedGroup(groups);
    final selectedGroupId = selectedGroup?.id.toInt();

    return PageSection(
      padding: EdgeInsets.all(widget.isDesktop ? 28 : 22),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderRow(
              title: l10n.createBill,
              trailing: IconButton(
                key: const ValueKey('bill-create-refresh-button'),
                tooltip: l10n.refreshBillFormData,
                onPressed: state.isLoading ? null : state.ensureLoaded,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.createBillDescription,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: mutedForegroundColor(context, alpha: 0.88),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            if (state.isLoading || groupState.isLoadingGroups)
              const LinearProgressIndicator(),
            if (state.errorMessage != null) ...[
              _InlineError(message: state.errorMessage!),
              const SizedBox(height: 16),
            ],
            if (groupState.errorMessage != null) ...[
              _InlineError(message: groupState.errorMessage!),
              const SizedBox(height: 16),
            ],
            _BasicsSection(
              titleController: _titleController,
              descriptionController: _descriptionController,
              amountController: _amountController,
              currency: _currency ?? 'EUR',
              onCurrencyChanged: (value) {
                setState(() {
                  _currency = value;
                  _syncShareControllers();
                });
              },
              onAmountChanged: (_) => _syncShareControllers(),
            ),
            const SizedBox(height: 22),
            _TagsSection(
              availableTags: state.availableTags,
              draftTags: _draftTags,
              selectedTags: _selectedTags,
              searchController: _tagSearchController,
              tagTextController: _tagTextController,
              tagEmoji: _tagEmoji,
              tagColor: _tagColor,
              onExistingTagToggled: _toggleExistingTag,
              onDraftTagToggled: _toggleDraftTag,
              onEmojiTap: _pickEmoji,
              onColorTap: _pickColor,
              onAddTag: _addCustomTag,
            ),
            const SizedBox(height: 22),
            _GroupAndSharesSection(
              groups: groups,
              selectedGroupId: selectedGroupId,
              selectedGroup: selectedGroup,
              amountFormat: _amountFormat(),
              shareDelta: _totalSharePercentDelta(),
              percentFormatter: _formatEditablePercent,
              ownerPercentController: _ownerPercentController,
              ownerAmountController: _ownerAmountController,
              percentControllers: _percentControllers,
              amountControllers: _shareAmountControllers,
              onGroupChanged: _selectGroup,
              onOwnerPercentChanged: (value) =>
                  _setSharePercent(_ownerShareKey, value),
              onOwnerAmountChanged: (value) =>
                  _setShareAmount(_ownerShareKey, value),
              onMemberPercentChanged: _setSharePercent,
              onMemberAmountChanged: _setShareAmount,
            ),
            const SizedBox(height: 22),
            TextFormField(
              key: const ValueKey('bill-create-notes-field'),
              controller: _notesController,
              minLines: 4,
              maxLines: 8,
              decoration: InputDecoration(
                labelText: l10n.notes,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 22),
            _AttachmentsSection(
              attachments: _attachments,
              isPickingFile: _isPickingFile,
              isPickingCamera: _isPickingCamera,
              isDesktop: widget.isDesktop,
              onUploadFiles: _pickFiles,
              onTakePicture: _takePicture,
              onRemove: _removeAttachment,
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                key: const ValueKey('bill-create-submit-button'),
                onPressed: state.isMutating ? null : _submit,
                icon: state.isMutating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(l10n.createBill),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Recipient? _selectedGroup(List<Recipient> groups) {
    final selectedId = _selectedGroupId;
    if (selectedId == null) {
      return null;
    }
    for (final group in groups) {
      if (group.id.toInt() == selectedId) {
        return group;
      }
    }
    return null;
  }

  List<Recipient> _ownedGroups(RecipientGroupState groupState) {
    final currentUserId = groupState.currentUserId;
    if (currentUserId == null) {
      return const [];
    }
    return groupState.groups
        .where((group) => group.ownerId.toInt() == currentUserId)
        .toList(growable: false);
  }

  NumberFormat _amountFormat() {
    final locale = Localizations.localeOf(context);
    return NumberFormat.currency(
      locale: locale.toString(),
      name: _currency ?? 'EUR',
      decimalDigits: 2,
    );
  }

  void _toggleExistingTag(TagIndex tag, bool selected) {
    setState(() {
      _selectedTags.removeWhere((draft) => draft.id == tag.id.toInt());
      if (selected) {
        _selectedTags.add(
          BillDraftTag(
            id: tag.id.toInt(),
            text: tag.text,
            icon: tag.icon,
            color: tag.color,
          ),
        );
      }
    });
  }

  void _toggleDraftTag(BillDraftTag tag, bool selected) {
    setState(() {
      _selectedTags.removeWhere(
        (draft) => draft.id == null && _sameTagText(draft.text, tag.text),
      );
      if (selected) {
        _selectedTags.add(tag);
      }
    });
  }

  Future<void> _pickEmoji() async {
    final l10n = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.pickEmoji),
          content: SizedBox(
            width: 360,
            height: 380,
            child: EmojiPicker(
              onEmojiSelected: (_, emoji) {
                setState(() {
                  _tagEmoji = emoji.emoji;
                });
                Navigator.of(dialogContext).pop();
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickColor() async {
    final l10n = AppLocalizations.of(context);
    var nextColor = _tagColor;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.pickTagColor),
          content: SingleChildScrollView(
            child: ColorPicker(
              color: nextColor,
              onColorChanged: (color) {
                nextColor = color;
              },
              pickersEnabled: const {
                ColorPickerType.primary: true,
                ColorPickerType.accent: true,
                ColorPickerType.wheel: true,
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  _tagColor = nextColor;
                });
                Navigator.of(dialogContext).pop();
              },
              child: Text(l10n.apply),
            ),
          ],
        );
      },
    );
  }

  void _addCustomTag() {
    final text = _tagTextController.text.trim();
    if (text.isEmpty) {
      return;
    }
    setState(() {
      final draft = BillDraftTag(
        text: text,
        icon: _tagEmoji,
        color: '#${_tagColor.hex}',
      );
      _draftTags.removeWhere((tag) => _sameTagText(tag.text, text));
      _draftTags.add(draft);
      _selectedTags.removeWhere(
        (tag) => tag.id == null && _sameTagText(tag.text, text),
      );
      _selectedTags.add(draft);
      _tagTextController.clear();
      _tagEmoji = '🏷️';
      _tagColor = brandPrimary;
    });
  }

  void _selectGroup(int? groupId) {
    setState(() {
      _selectedGroupId = groupId;
      _sharePercents.clear();
      Recipient? selected;
      if (groupId != null) {
        for (final candidate in _ownedGroups(
          context.read<RecipientGroupState>(),
        )) {
          if (candidate.id.toInt() == groupId) {
            selected = candidate;
            break;
          }
        }
      }
      if (selected == null || selected.members.isEmpty) {
        _sharePercents[_ownerShareKey] = 100;
      } else {
        _sharePercents[_ownerShareKey] = 0;
        final equalShare = 100 / selected.members.length;
        for (final member in selected.members) {
          _sharePercents[member.id.toInt()] = equalShare;
        }
      }
      _syncShareControllers();
    });
  }

  void _setSharePercent(int userId, String rawValue) {
    final value = _parseLocalizedNumber(rawValue);
    if (value == null) {
      return;
    }
    setState(() {
      _sharePercents[userId] = value.clamp(0, 100).toDouble();
      _syncSingleShareAmount(userId);
    });
  }

  void _setShareAmount(int userId, String rawValue) {
    final amount = _parseLocalizedNumber(rawValue);
    final total = _parseLocalizedNumber(_amountController.text);
    if (amount == null || total == null || total <= 0) {
      return;
    }
    setState(() {
      _sharePercents[userId] = (amount * 100 / total).clamp(0, 100).toDouble();
      _syncSingleSharePercent(userId);
    });
  }

  void _syncShareControllers() {
    final userIds = _sharePercents.keys.toSet();
    _percentControllers.keys
        .where((userId) => !userIds.contains(userId))
        .toList()
        .forEach((userId) => _percentControllers.remove(userId)?.dispose());
    _shareAmountControllers.keys
        .where((userId) => !userIds.contains(userId))
        .toList()
        .forEach((userId) => _shareAmountControllers.remove(userId)?.dispose());

    for (final userId in userIds) {
      if (userId == _ownerShareKey) {
        _ownerPercentController.text = _formatEditablePercent(
          _sharePercents[userId] ?? 0,
        );
        _syncSingleShareAmount(userId);
      } else {
        _percentControllers
            .putIfAbsent(userId, () => TextEditingController())
            .text = _formatEditablePercent(
          _sharePercents[userId] ?? 0,
        );
        _shareAmountControllers.putIfAbsent(
          userId,
          () => TextEditingController(),
        );
        _syncSingleShareAmount(userId);
      }
    }
  }

  void _syncSingleShareAmount(int userId) {
    final amount = _parseLocalizedNumber(_amountController.text);
    final percent = _sharePercents[userId] ?? 0;
    final value = amount == null ? 0.0 : amount * percent / 100;
    final formatted = _formatEditableAmount(value);
    if (userId == _ownerShareKey) {
      _ownerAmountController.text = formatted;
    } else {
      _shareAmountControllers[userId]?.text = formatted;
    }
  }

  void _syncSingleSharePercent(int userId) {
    final formatted = _formatEditablePercent(_sharePercents[userId] ?? 0);
    if (userId == _ownerShareKey) {
      _ownerPercentController.text = formatted;
    } else {
      _percentControllers[userId]?.text = formatted;
    }
  }

  Future<void> _pickFiles() async {
    setState(() => _isPickingFile = true);
    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: true,
        withData: true,
      );
      if (result == null) {
        return;
      }
      final next = <_AttachmentDraft>[];
      for (final file in result.files) {
        final bytes = file.bytes ?? await file.xFile.readAsBytes();
        next.add(
          _AttachmentDraft(
            filename: file.name,
            bytes: Uint8List.fromList(bytes),
            contentType: _guessContentType(file.name),
          ),
        );
      }
      setState(() => _attachments.addAll(next));
    } finally {
      if (mounted) {
        setState(() => _isPickingFile = false);
      }
    }
  }

  Future<void> _takePicture() async {
    setState(() => _isPickingCamera = true);
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.camera);
      if (image == null) {
        return;
      }
      final bytes = await image.readAsBytes();
      setState(() {
        _attachments.add(
          _AttachmentDraft(
            filename: image.name,
            bytes: bytes,
            contentType: _guessContentType(image.name) ?? 'image/jpeg',
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isPickingCamera = false);
      }
    }
  }

  void _removeAttachment(_AttachmentDraft attachment) {
    setState(() {
      _attachments.remove(attachment);
      attachment.dispose();
    });
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      return;
    }
    final amount = _parseLocalizedNumber(_amountController.text);
    if (amount == null || amount <= 0) {
      return;
    }
    final selectedGroup = _selectedGroup(
      _ownedGroups(context.read<RecipientGroupState>()),
    );
    final selectedGroupId = selectedGroup?.id.toInt();
    if (selectedGroupId != null && _totalSharePercentDelta().abs() > 0.01) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.sharesMustAddTo100)));
      return;
    }

    final state = context.read<BillCreationState>();
    final saved = await state.saveBill(
      title: _titleController.text,
      description: _descriptionController.text,
      amountOwed: amount,
      currency: _currency ?? 'EUR',
      recipientId: selectedGroupId,
      notes: _notesController.text,
      ownerSharePercent: selectedGroupId == null
          ? null
          : (_sharePercents[_ownerShareKey] ?? 0),
      recipientShares: selectedGroupId == null
          ? const []
          : _sharePercents.entries
                .where((entry) => entry.key != _ownerShareKey)
                .map(
                  (entry) => BillDraftShare(
                    userId: entry.key,
                    sharePercent: entry.value,
                  ),
                ),
      tags: _selectedTags,
      attachments: _attachments.map(
        (attachment) => BillDraftAttachment(
          filename: attachment.filenameController.text,
          bytes: attachment.bytes,
          contentType: attachment.contentType,
        ),
      ),
    );
    if (!mounted || saved == null) {
      return;
    }
    await context.read<BillListState>().refresh();
    if (!mounted) {
      return;
    }
    _resetForm();
    context.read<NavigationState>().selectDestination(AppDestination.bills);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.billCreated)));
  }

  double _totalSharePercentDelta() {
    return _sharePercents.values.fold<double>(0, (sum, value) => sum + value) -
        100;
  }

  void _resetForm() {
    _titleController.clear();
    _descriptionController.clear();
    _amountController.clear();
    _notesController.clear();
    _tagTextController.clear();
    for (final attachment in _attachments) {
      attachment.dispose();
    }
    _attachments.clear();
    _selectedTags.clear();
    _draftTags.clear();
    _selectedGroupId = null;
    _sharePercents
      ..clear()
      ..[_ownerShareKey] = 100;
    _syncShareControllers();
  }

  double? _parseLocalizedNumber(String raw) {
    final locale = Localizations.localeOf(context);
    return parseLocalizedDecimal(raw, locale);
  }

  String _formatEditableAmount(double amount) {
    final locale = Localizations.localeOf(context);
    final separator = NumberFormat.decimalPattern(
      locale.toString(),
    ).symbols.DECIMAL_SEP;
    return amount.toStringAsFixed(2).replaceAll('.', separator);
  }

  String _formatEditablePercent(double percent) {
    final locale = Localizations.localeOf(context);
    final separator = NumberFormat.decimalPattern(
      locale.toString(),
    ).symbols.DECIMAL_SEP;
    final fixed = percent.toStringAsFixed(percent % 1 == 0 ? 0 : 2);
    return fixed.replaceAll('.', separator);
  }
}

class _LoggedOutBillCreationSection extends StatelessWidget {
  const _LoggedOutBillCreationSection({required this.isDesktop});

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PageSection(
      padding: EdgeInsets.all(isDesktop ? 28 : 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.createBill,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.loginToCreateBills,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: mutedForegroundColor(context, alpha: 0.88),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            key: const ValueKey('bill-create-login-button'),
            onPressed: context.read<AuthSessionState>().login,
            icon: const Icon(Icons.login_rounded),
            label: Text(l10n.loginToCreateBills),
          ),
        ],
      ),
    );
  }
}

class _BasicsSection extends StatelessWidget {
  const _BasicsSection({
    required this.titleController,
    required this.descriptionController,
    required this.amountController,
    required this.currency,
    required this.onCurrencyChanged,
    required this.onAmountChanged,
  });

  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController amountController;
  final String currency;
  final ValueChanged<String> onCurrencyChanged;
  final ValueChanged<String> onAmountChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _SectionBlock(
      title: l10n.details,
      child: Column(
        children: [
          TextFormField(
            key: const ValueKey('bill-create-title-field'),
            controller: titleController,
            maxLength: BillCreationState.maxTitleLength,
            decoration: InputDecoration(labelText: l10n.title),
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty) {
                return l10n.titleRequired;
              }
              if (text.length > BillCreationState.maxTitleLength) {
                return l10n.titleTooLong;
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const ValueKey('bill-create-description-field'),
            controller: descriptionController,
            maxLength: BillCreationState.maxDescriptionLength,
            decoration: InputDecoration(labelText: l10n.shortDescription),
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.length > BillCreationState.maxDescriptionLength) {
                return l10n.descriptionTooLong;
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  key: const ValueKey('bill-create-amount-field'),
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(labelText: l10n.amount),
                  onChanged: onAmountChanged,
                  validator: (value) {
                    final amount = parseLocalizedDecimal(
                      value ?? '',
                      Localizations.localeOf(context),
                    );
                    if (amount == null || amount <= 0) {
                      return l10n.validAmountRequired;
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: const ValueKey('bill-create-currency-field'),
                  initialValue: currency,
                  decoration: InputDecoration(labelText: l10n.currency),
                  items: const ['EUR', 'USD', 'GBP', 'CHF', 'JPY', 'PLN']
                      .map(
                        (currency) => DropdownMenuItem(
                          value: currency,
                          child: Text(currency),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      onCurrencyChanged(value);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TagsSection extends StatelessWidget {
  const _TagsSection({
    required this.availableTags,
    required this.draftTags,
    required this.selectedTags,
    required this.searchController,
    required this.tagTextController,
    required this.tagEmoji,
    required this.tagColor,
    required this.onExistingTagToggled,
    required this.onDraftTagToggled,
    required this.onEmojiTap,
    required this.onColorTap,
    required this.onAddTag,
  });

  final List<TagIndex> availableTags;
  final List<BillDraftTag> draftTags;
  final List<BillDraftTag> selectedTags;
  final TextEditingController searchController;
  final TextEditingController tagTextController;
  final String tagEmoji;
  final Color tagColor;
  final void Function(TagIndex tag, bool selected) onExistingTagToggled;
  final void Function(BillDraftTag tag, bool selected) onDraftTagToggled;
  final VoidCallback onEmojiTap;
  final VoidCallback onColorTap;
  final VoidCallback onAddTag;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _SectionBlock(
      title: l10n.tags,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            key: const ValueKey('bill-create-tag-search-field'),
            controller: searchController,
            decoration: InputDecoration(
              labelText: l10n.searchRecommendedTags,
              prefixIcon: const Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: searchController,
            builder: (context, _) {
              final query = searchController.text.trim().toLowerCase();
              final visibleExisting = availableTags
                  .where(
                    (tag) =>
                        query.isEmpty || tag.text.toLowerCase().contains(query),
                  )
                  .toList(growable: false);
              final visibleDrafts = draftTags
                  .where(
                    (tag) =>
                        query.isEmpty || tag.text.toLowerCase().contains(query),
                  )
                  .toList(growable: false);
              if (visibleExisting.isEmpty && visibleDrafts.isEmpty) {
                return Text(
                  query.isEmpty ? l10n.noRecommendedTags : l10n.noTagsMatch,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: mutedForegroundColor(context, alpha: 0.78),
                  ),
                );
              }
              return ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 190),
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...visibleExisting.map((tag) {
                        final selected = selectedTags.any(
                          (draft) => draft.id == tag.id.toInt(),
                        );
                        return FilterChip(
                          selected: selected,
                          avatar: Text(tag.icon),
                          label: Text(tag.text),
                          onSelected: (value) =>
                              onExistingTagToggled(tag, value),
                        );
                      }),
                      ...visibleDrafts.map((tag) {
                        final selected = selectedTags.any(
                          (draft) =>
                              draft.id == null &&
                              _sameTagText(draft.text, tag.text),
                        );
                        return FilterChip(
                          selected: selected,
                          avatar: Text(tag.icon),
                          label: Text(tag.text),
                          onSelected: (value) => onDraftTagToggled(tag, value),
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              IconButton.filledTonal(
                key: const ValueKey('bill-create-tag-emoji-button'),
                tooltip: l10n.pickTagEmoji,
                onPressed: onEmojiTap,
                icon: Text(tagEmoji),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                key: const ValueKey('bill-create-tag-color-button'),
                tooltip: l10n.pickTagColor,
                onPressed: onColorTap,
                icon: Icon(Icons.palette_rounded, color: tagColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  key: const ValueKey('bill-create-tag-text-field'),
                  controller: tagTextController,
                  maxLength: 256,
                  decoration: InputDecoration(
                    labelText: l10n.newTag,
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                key: const ValueKey('bill-create-add-tag-button'),
                onPressed: onAddTag,
                tooltip: l10n.add,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          if (selectedTags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selectedTags
                  .map(
                    (tag) => Chip(
                      avatar: Text(tag.icon),
                      label: Text(tag.text),
                      backgroundColor: _parseTagColor(
                        tag.color,
                      ).withValues(alpha: 0.14),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _GroupAndSharesSection extends StatelessWidget {
  const _GroupAndSharesSection({
    required this.groups,
    required this.selectedGroupId,
    required this.selectedGroup,
    required this.amountFormat,
    required this.shareDelta,
    required this.percentFormatter,
    required this.ownerPercentController,
    required this.ownerAmountController,
    required this.percentControllers,
    required this.amountControllers,
    required this.onGroupChanged,
    required this.onOwnerPercentChanged,
    required this.onOwnerAmountChanged,
    required this.onMemberPercentChanged,
    required this.onMemberAmountChanged,
  });

  final List<Recipient> groups;
  final int? selectedGroupId;
  final Recipient? selectedGroup;
  final NumberFormat amountFormat;
  final double shareDelta;
  final String Function(double value) percentFormatter;
  final TextEditingController ownerPercentController;
  final TextEditingController ownerAmountController;
  final Map<int, TextEditingController> percentControllers;
  final Map<int, TextEditingController> amountControllers;
  final ValueChanged<int?> onGroupChanged;
  final ValueChanged<String> onOwnerPercentChanged;
  final ValueChanged<String> onOwnerAmountChanged;
  final void Function(int userId, String value) onMemberPercentChanged;
  final void Function(int userId, String value) onMemberAmountChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _SectionBlock(
      title: l10n.groupAndShares,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<int?>(
            key: const ValueKey('bill-create-group-field'),
            initialValue: selectedGroupId,
            isExpanded: true,
            decoration: InputDecoration(labelText: l10n.group),
            items: [
              DropdownMenuItem<int?>(
                value: null,
                child: Text(l10n.personalBill),
              ),
              ...groups.map(
                (group) => DropdownMenuItem<int?>(
                  value: group.id.toInt(),
                  child: Text(group.name),
                ),
              ),
            ],
            onChanged: onGroupChanged,
          ),
          const SizedBox(height: 16),
          _ShareRow(
            key: const ValueKey('bill-create-owner-share-row'),
            label: l10n.owner,
            amountFormat: amountFormat,
            percentController: ownerPercentController,
            amountController: ownerAmountController,
            onPercentChanged: onOwnerPercentChanged,
            onAmountChanged: onOwnerAmountChanged,
          ),
          if (selectedGroup != null)
            ...selectedGroup!.members.map(
              (member) => Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _ShareRow(
                  key: ValueKey('bill-create-member-${member.id.toInt()}-row'),
                  label: _userLabel(member, l10n),
                  amountFormat: amountFormat,
                  percentController:
                      percentControllers[member.id.toInt()] ??
                      TextEditingController(text: '0'),
                  amountController:
                      amountControllers[member.id.toInt()] ??
                      TextEditingController(text: '0'),
                  onPercentChanged: (value) =>
                      onMemberPercentChanged(member.id.toInt(), value),
                  onAmountChanged: (value) =>
                      onMemberAmountChanged(member.id.toInt(), value),
                ),
              ),
            ),
          const SizedBox(height: 12),
          _ShareTotalIndicator(
            delta: shareDelta,
            percentFormatter: percentFormatter,
          ),
        ],
      ),
    );
  }
}

class _ShareTotalIndicator extends StatelessWidget {
  const _ShareTotalIndicator({
    required this.delta,
    required this.percentFormatter,
  });

  final double delta;
  final String Function(double value) percentFormatter;

  @override
  Widget build(BuildContext context) {
    final complete = delta.abs() <= 0.01;
    final l10n = AppLocalizations.of(context);
    final label = complete
        ? l10n.complete100
        : delta < 0
        ? l10n.needPercent(percentFormatter(-delta))
        : l10n.reducePercent(percentFormatter(delta));
    final color = complete ? Colors.green : Theme.of(context).colorScheme.error;
    return Row(
      key: const ValueKey('bill-create-share-total-indicator'),
      children: [
        Icon(
          complete ? Icons.check_circle_rounded : Icons.error_outline_rounded,
          size: 18,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ShareRow extends StatelessWidget {
  const _ShareRow({
    super.key,
    required this.label,
    required this.amountFormat,
    required this.percentController,
    required this.amountController,
    required this.onPercentChanged,
    required this.onAmountChanged,
  });

  final String label;
  final NumberFormat amountFormat;
  final TextEditingController percentController;
  final TextEditingController amountController;
  final ValueChanged<String> onPercentChanged;
  final ValueChanged<String> onAmountChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 96,
          child: TextField(
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: amountFormat.currencyName,
              isDense: true,
            ),
            onChanged: onAmountChanged,
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 84,
          child: TextField(
            controller: percentController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: '%', isDense: true),
            onChanged: onPercentChanged,
          ),
        ),
      ],
    );
  }
}

class _AttachmentsSection extends StatelessWidget {
  const _AttachmentsSection({
    required this.attachments,
    required this.isPickingFile,
    required this.isPickingCamera,
    required this.isDesktop,
    required this.onUploadFiles,
    required this.onTakePicture,
    required this.onRemove,
  });

  final List<_AttachmentDraft> attachments;
  final bool isPickingFile;
  final bool isPickingCamera;
  final bool isDesktop;
  final VoidCallback onUploadFiles;
  final VoidCallback onTakePicture;
  final ValueChanged<_AttachmentDraft> onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _SectionBlock(
      title: l10n.files,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                key: const ValueKey('bill-create-upload-file-button'),
                onPressed: isPickingFile ? null : onUploadFiles,
                icon: const Icon(Icons.upload_file_rounded),
                label: Text(l10n.upload),
              ),
              OutlinedButton.icon(
                key: const ValueKey('bill-create-camera-button'),
                onPressed: isDesktop || isPickingCamera ? null : onTakePicture,
                icon: const Icon(Icons.photo_camera_rounded),
                label: Text(l10n.takePicture),
              ),
            ],
          ),
          if (isDesktop) ...[
            const SizedBox(height: 8),
            Text(
              l10n.takePictureMobileOnly,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: mutedForegroundColor(context, alpha: 0.78),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (attachments.isNotEmpty) ...[
            const SizedBox(height: 14),
            ...attachments.map(
              (attachment) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Icon(_fileIcon(attachment.contentType)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: attachment.filenameController,
                        decoration: InputDecoration(
                          labelText: l10n.filename,
                          isDense: true,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.removeFile,
                      onPressed: () => onRemove(attachment),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AttachmentDraft {
  _AttachmentDraft({
    required String filename,
    required this.bytes,
    required this.contentType,
  }) : filenameController = TextEditingController(text: filename);

  final TextEditingController filenameController;
  final Uint8List bytes;
  final String? contentType;

  void dispose() {
    filenameController.dispose();
  }
}

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GlassPanel.secondary(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      borderRadius: const BorderRadius.all(Radius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.title, required this.trailing});

  final String title;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        trailing,
      ],
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: scheme.error,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

double? parseLocalizedDecimal(String raw, Locale locale) {
  var normalized = raw.trim().replaceAll(RegExp(r'\s+'), '');
  if (normalized.isEmpty) {
    return null;
  }
  final separator = NumberFormat.decimalPattern(
    locale.toString(),
  ).symbols.DECIMAL_SEP;
  if (separator == ',') {
    normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
  } else {
    normalized = normalized.replaceAll(',', '');
  }
  return double.tryParse(normalized);
}

String? _guessContentType(String filename) {
  final lower = filename.toLowerCase();
  if (lower.endsWith('.pdf')) {
    return 'application/pdf';
  }
  if (lower.endsWith('.png')) {
    return 'image/png';
  }
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
    return 'image/jpeg';
  }
  if (lower.endsWith('.webp')) {
    return 'image/webp';
  }
  return null;
}

IconData _fileIcon(String? contentType) {
  if (contentType == 'application/pdf') {
    return Icons.picture_as_pdf_rounded;
  }
  if (contentType?.startsWith('image/') == true) {
    return Icons.image_rounded;
  }
  return Icons.insert_drive_file_rounded;
}

String _userLabel(User user, AppLocalizations l10n) {
  if (user.deleted) {
    return l10n.deletedUser;
  }
  if (user.hasName() && user.name.trim().isNotEmpty) {
    return user.name;
  }
  if (user.hasEmail() && user.email.trim().isNotEmpty) {
    return user.email;
  }
  return '${l10n.user} ${user.id}';
}

bool _sameTagText(String left, String right) {
  return left.trim().toLowerCase() == right.trim().toLowerCase();
}

Color _parseTagColor(String value) {
  final hex = value.trim().replaceFirst('#', '');
  final parsed = int.tryParse(hex.length == 6 ? 'FF$hex' : hex, radix: 16);
  if (parsed == null) {
    return brandPrimary;
  }
  return Color(parsed);
}
