import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_widgets/texts/section_text_name.dart';
import 'package:sipged/_widgets/list/files/attachment.dart';
import 'package:sipged/_widgets/list/files/side_list_box.dart';

import 'package:sipged/_blocs/modules/actives/oacs/active_oacs_cubit.dart';
import 'package:sipged/_blocs/modules/actives/oacs/active_oacs_state.dart';
import 'package:sipged/_blocs/modules/actives/oacs/active_oacs_data.dart';
import 'package:sipged/_blocs/modules/actives/oacs/active_oacs_repository.dart';

class OacDocumentsPage extends StatefulWidget {
  const OacDocumentsPage({super.key});

  @override
  State<OacDocumentsPage> createState() => _OacDocumentsPageState();
}

class _OacDocumentsPageState extends State<OacDocumentsPage> {
  final _repo = ActiveOacsRepository();

  List<Attachment> _docs(ActiveOacsData d) => (d.attachments ?? const <Attachment>[]);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ActiveOacsCubit, ActiveOacsState>(
      builder: (context, st) {
        final cubit = context.read<ActiveOacsCubit>();
        final oac = st.form;

        if (oac.id == null || oac.id!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Salve a OAC primeiro para liberar Documentos.'),
          );
        }

        Future<void> onAddDoc() async {
          final att = await _repo.pickAndUploadSingle(
            baseDir: 'actives_oacs/${oac.id}/documents',
            allowedExtensions: null,
            forcedLabel: null,
          );
          if (att == null) return;

          final updated = List<Attachment>.from(_docs(oac))..insert(0, att);
          cubit.patchForm(oac.copyWith(attachments: updated));
          await cubit.upsert(cubit.state.form);
          if (mounted) setState(() {});
        }


        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(text: 'Documentos da OAC'),
              const SizedBox(height: 8),
              Expanded(
                child: SideListBox(
                  title: 'Anexos gerais (projetos, as built, fotos, relatórios, etc.)',
                  items: _docs(oac),
                  onAddPressed: st.saving ? null : onAddDoc,
                  //onDelete: st.saving ? null : onDeleteDoc,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
